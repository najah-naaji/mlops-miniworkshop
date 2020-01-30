./#!/bin/bash
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

# Provision infrastructure to host KFP components

if [[ $# < 2 ]]; then
  echo "Error: Arguments missing. [PROJECT_ID] [NAME_PREFIX]"
  exit 1
fi

PROJECT_ID=${1}
NAME_PREFIX=${2}
ZONE=${3:-us-central1-a}

AR=${1:-DEFAULTVALUE}

### Configure KPF infrastructure
pushd terraform

# Start terraform build
terraform init
terraform apply  \
-var "project_id=$PROJECT_ID" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX"

### Retrieve resource names
CLUSTER_NAME=$(terraform output cluster_name)
KFP_SA_EMAIL=$(terraform output kfp_sa_email)
BUCKET_NAME=$(terraform output artifact_store_bucket)

popd

if [ $? -eq 0 ]; then
    echo Infrastructure provisioned successfully
else
    exit $?
fi


# Deploy Kubeflow Pipelines

gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE

export PIPELINE_VERSION=0.1.36
kubectl apply -f https://storage.googleapis.com/ml-pipeline/pipeline-lite/$PIPELINE_VERSION/namespaced-install.yaml

if [ $? -eq 0 ]; then
    echo Kubeflow Pipelines deployed to the kubeflow namespace
else
    exit $?
fi

# Configure user-gpc-sa with a private key of the KFP service account
gcloud iam service-accounts keys create application_default_credentials.json --iam-account=$KFP_SA_EMAIL
kubectl create secret -n kubeflow generic user-gcp-sa --from-file=application_default_credentials.json --from-file=user-gcp-sa.json=application_default_credentials.json
rm application_default_credentials.json


