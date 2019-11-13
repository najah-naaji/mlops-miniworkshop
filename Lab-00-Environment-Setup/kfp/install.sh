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

# Deploy Kubeflow Pipelines on GCP

if [[ $# < 7 ]]; then
  echo "Error: Arguments missing. [PROJECT_ID REGION ZONE NAME_PREFIX NAMESPACE SQL_USERNAME SQL_PASSWORD]"
  exit 1
fi

PROJECT_ID=${1}
REGION=${2} 
ZONE=${3}
NAME_PREFIX=${4}
NAMESPACE=${5}
SQL_USERNAME=${6}
SQL_PASSWORD=${7}

### Configure KPF infrastructure
pushd terraform

# Start terraform build
terraform init
terraform apply  \
-var "project_id=$PROJECT_ID" \
-var "region=$REGION" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX"

# Retrieve resource names
CLUSTER_NAME=$(terraform output cluster_name)
KFP_SA_EMAIL=$(terraform output kfp_sa_email)
SQL_INSTANCE_NAME=$(terraform output sql_name)
SQL_CONNECTION_NAME=$(terraform output sql_connection_name)
BUCKET_NAME=$(terraform output artifact_store_bucket)

popd

### Install KFP
pushd kustomize

# Create a namespace for KFP components
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
kubectl create namespace $NAMESPACE
kustomize edit set namespace $NAMESPACE

# Configure user-gpc-sa with a private key of the KFP service account
gcloud iam service-accounts keys create application_default_credentials.json --iam-account=$KFP_SA_EMAIL
kubectl create secret -n $NAMESPACE generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
rm application_default_credentials.json

# Create a Cloud SQL database user and store its credentials in mysql-credential secret
gcloud sql users create $SQL_USERNAME --instance=$SQL_INSTANCE_NAME --password=$SQL_PASSWORD --project $PROJECT_ID
kubectl create secret -n $NAMESPACE generic mysql-credential --from-literal=username=$SQL_USERNAME --from-literal=password=$SQL_PASSWORD

# Generate an environment file with connection settings to Cloud SQL and artifact store
cat > gcp-configs.env << EOF
sql_connection_name=$SQL_CONNECTION_NAME
bucket_name=$BUCKET_NAME
EOF

# Deploy KFP to the cluster
kustomize build . | kubectl apply -f -

popd




