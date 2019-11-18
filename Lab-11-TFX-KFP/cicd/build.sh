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
#
# Submits a Cloud Build job that builds and deploys
# the pipelines and pipelines components 

SUBSTITUTIONS=\
_PIPELINE_NAME=online_news_training_pipeline,\
_PIPELINE_IMAGE=online_news_training_pipeline,\
_GCP_REGION=us-central1,\
_ARTIFACT_STORE_BUCKET=kfp-tfx-demo-artifact-store,\
_PIPELINE_FOLDER=online_news,\
_PIPELINE_DSL=pipeline_dsl.py,\
_TAG_NAME=latest,\
_CLUSTER_NAME=kfp-tfx-demo-cluster,\
_ZONE=us-central1-a

gcloud builds submit ../pipelines --config cloudbuild.yaml --substitutions $SUBSTITUTIONS

