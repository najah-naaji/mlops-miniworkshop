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

# Destory KFP environment

if [[ $# < 1 ]]; then
  echo 'USAGE:  ./destroy.sh PROJECT_ID [NAME_PREFIX=PROJECT_ID]  [ZONE=us-central1-a]'
  exit 1
fi

PROJECT_ID=${1}
NAME_PREFIX=${2:-$PROJECT_ID} 
ZONE=${3:-us-central1-a}

INSTANCE_NAME=${NAME_PREFIX}-notebook

if [ $(gcloud compute instances list --filter="name=$INSTANCE_NAME" --zones $ZONE --format="value(name)") ]; then
    echo INFO: Instance $INSTANCE_NAME exists in $ZONE. Destroying ...
    gcloud compute instances delete $INSTANCE_NAME --zone $ZONE
else
    echo INFO: No $INSTANCE_NAME instance in $ZONE
fi

echo INFO: Destroying KFP environment
pushd terraform
terraform destroy \
-var "project_id=$PROJECT_ID" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX" 
popd