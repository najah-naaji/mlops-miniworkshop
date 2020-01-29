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

# Provision infrastructure to host KFP components

if [[ $# < 4 ]]; then
  echo "Error: Arguments missing. [PROJECT_ID] [REGION] [ZONE] [NAME_PREFIX]"
  exit 1
fi

PROJECT_ID=${1}
REGION=${2} 
ZONE=${3}
NAME_PREFIX=${4}

### Configure KPF infrastructure
pushd terraform

# Start terraform build
terraform init
terraform apply  \
-var "project_id=$PROJECT_ID" \
-var "region=$REGION" \
-var "zone=$ZONE" \
-var "name_prefix=$NAME_PREFIX"

popd






