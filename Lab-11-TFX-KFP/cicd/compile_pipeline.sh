#!/bin/bash

export PROJECT_ID=jk-tfw-demo
export PIPELINE_NAME=online_news_training_pipeline
export PIPELINE_IMAGE=online_news_training_pipeline
export GCP_REGION=us-central1
export ARTIFACT_STORE_BUCKET=gs://tfw-demo-artifact-store

tfx pipeline compile --pipeline_path ../pipelines/online_news/pipeline_dsl.py