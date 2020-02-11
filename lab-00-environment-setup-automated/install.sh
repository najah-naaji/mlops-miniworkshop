#!/bin/bash
# Copyright 2019 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#            http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Provision MLOPs environment

# Set up a global error handler
err_handler() {
    echo "Error on line: $1"
    echo "Caused by: $2"
    echo "That returned exit status: $3"
    echo "Aborting..."
    exit $3
}

trap 'err_handler "$LINENO" "$BASH_COMMAND" "$?"' ERR

# Check command line parameters
if [[ $# < 1 ]]; then
  echo 'USAGE:  ./install.sh PROJECT_ID [NAME_PREFIX=PROJECT_ID] [ZONE=us-central1-a]'
  exit 1
fi

# Set script constants

PROJECT_ID=${1}
NAME_PREFIX=${2:-$PROJECT_ID} 
ZONE=${4:-us-central1-a}

IMAGE_NAME=mlops-labs-image
TAG=latest
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

INSTANCE_NAME=${NAME_PREFIX}-notebook
IMAGE_FAMILY="common-container"
IMAGE_PROJECT="deeplearning-platform-release"
INSTANCE_TYPE="n1-standard-4"
METADATA="proxy-mode=service_account,container=$IMAGE_URI"


# Enable services
echo INFO: Enabling required services
gcloud config set project $PROJECT_ID

gcloud services enable \
cloudbuild.googleapis.com \
container.googleapis.com \
cloudresourcemanager.googleapis.com \
iam.googleapis.com \
containerregistry.googleapis.com \
containeranalysis.googleapis.com \
ml.googleapis.com 

echo INFO: Required services enabled

# Give Cloud Build service account the project editor role
echo INFO:Assigning the Cloud Build service account to the project editor role
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CLOUD_BUILD_SERVICE_ACCOUNT="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$CLOUD_BUILD_SERVICE_ACCOUNT \
  --role roles/editor

# Provision an AI Platform Notebook instance

INSTANCE_NAME=${NAME_PREFIX}-notebook

if [ $(gcloud compute instances list --filter="name=$INSTANCE_NAME" --zones $ZONE --format="value(name)") ]; then
    echo INFO: Instance $INSTANCE_NAME exists in $ZONE. Skipping provisioning
else
    # Build the AI Platform Notebook image
    echo INFO: Building AI Platform Notebooks container image: $IMAGE_URI
    gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
    
    # Provision the AI Platform Notebook instance
    echo INFO: Starting provisioning of $INSTANCE_NAME in $ZONE
    gcloud compute instances create $INSTANCE_NAME \
    --zone=$ZONE \
    --image-family=$IMAGE_FAMILY \
    --machine-type=$INSTANCE_TYPE \
    --image-project=$IMAGE_PROJECT \
    --maintenance-policy=TERMINATE \
    --boot-disk-device-name=$INSTANCE_NAME-disk \
    --boot-disk-size=100GB \
    --boot-disk-type=pd-ssd \
    --scopes=cloud-platform,userinfo-email \
    --metadata=$METADATA
fi

# Configure KFP infrastructure
pushd terraform

# Start terraform build
echo INFO: Provisioning KFP infrastructure 

terraform init
terraform apply  \
-auto-approve \
-var "project_id=$PROJECT_ID" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX" 

echo INFO: KFP infrastructure provisioned successfully

# Deploy KFP
echo INFO: Deploying KFP to ${NAME_PREFIX}-cluster GKE cluster

### Retrieve resource names
CLUSTER_NAME=$(terraform output cluster_name)
KFP_SA_EMAIL=$(terraform output kfp_sa_email)
BUCKET_NAME=$(terraform output artifact_store_bucket)

popd

# Get credentials to the KFP cluster
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

export PIPELINE_VERSION=0.1.36
kubectl apply -f https://storage.googleapis.com/ml-pipeline/pipeline-lite/$PIPELINE_VERSION/namespaced-install.yaml

# Configure user-gpc-sa with a private key of the KFP service account
gcloud iam service-accounts keys create application_default_credentials.json --iam-account=$KFP_SA_EMAIL
kubectl create secret -n kubeflow generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
rm application_default_credentials.json

echo INFO: KFP deployed successfully
echo INFO: Sleeping for 180 seconds to wait for KFP services to start

sleep 180

echo INFO: KFP UI can be accessed at the below URI:
echo "https://"$(kubectl describe configmap inverse-proxy-config -n kubeflow | grep "googleusercontent.com")
