# Orchestrating model training and deployment with TFX on KFP

In this lab you will develop, deploy and run a TFX pipeline that uses Kubeflow Pipelines as an orchestrator.


## Lab scenario

You will be working with the [Covertype Data Set](https://github.com/jarokaz/mlops-labs/blob/master/datasets/covertype/README.md) dataset. 

The pipeline implements a typical TFX workflow as depicted on the below diagram:

![Lab 03 diagram](../images/lab-03-diagram.png).

The source data in a CSV file format is in the GCS bucket.

The TFX components run containers orchestrated by Kubeflow Pipelines.


## Lab setup

### AI Platform Notebook and KFP environment
Before proceeding with the lab, you must set up an **AI Platform Notebooks** instance and a **KFP** environment as detailed in `lab-01-environment-setup`.

### Lab dataset

The TFX pipeline in the lab is designed to ingest the *Covertype Data Set* in the CSV format from the GCS location. To prepare for the lab  upload the file to a subfolder in the artifact store bucket created during the setup.


1. Upload the *Covertype Data Set* CSV file
```
BUCKET_NAME=[YOUR_ARTIFACT_BUCKET]
COVERTYPE_GCS_PATH=${BUCKET_NAME}/covertype_dataset/
gsutil cp gs://workshop-datasets/covertype/full/dataset.csv $COVERTYPE_GCS_PATH
```
3. Verify that the file was uploaded 
```
gsutil ls $COVERTYPE_GCS_PATH
```
where

[YOUR_ARTIFACT_BUCKET] is a GCS bucket created during setup - `gs://[YOUR_PREFIX]-artifact-store`

## Lab Exercises

Follow the instructor who will walk you through the lab. The high level summary of the lab flow is as follows:

### Understanding the pipeline's DSL.

The pipeline uses the [tensorflow/tfx:0.15.0 image](https://hub.docker.com/r/tensorflow/tfx), as a runtime execution environment for the pipeline's components. 

The `Transform` and `Train` components are configured to retrieve the module file with the preprocessing and training code from the folder in the artifact store GCS bucket.

All code executes in containers on the GKE cluster.



### Building and deploying the pipeline

You will start by building a runtime image and pushing it to your project's **Container Registry**. Since the base [tensorflow/tfx:0.15.0 image](https://hub.docker.com/r/tensorflow/tfx) is not modified, we could refer to it directly in the pipeline's DSL; however creating the derivative image template will make it easier to do any modifications in future.

Start by configuring your environment settings:
```
export PROJECT_ID=[YOUR_PROJECT_ID]
export ARTIFACT_STORE_URI=[YOUR_ARTIFACT_STORE_URI]
export KFP_INVERSE_PROXY_HOST=[YOUR_INVERSE_PROXY_HOST]

export DATA_ROOT_URI=${ARTIFACT_STORE_URI}/covertype_dataset/
export TFX_IMAGE_URI=gcr.io/${PROJECT_ID}/tfx-image:latest
export MODULE_FILE_URI=${ARTIFACT_STORE_URI}/modules/transform_train.py
export PIPELINE_NAME=tfx_covertype_classifier_training
export GCP_REGION=us-central1
```

Where 
- [YOUR_ARTIFACT_STORE_URI] is the URI of the bucket created during the KFP environment setup - `gs://[PREFIX]-artifact-store`
- [YOUR_TFX_IMAGE_URI] is the URI of the image you created in the previous step. Make sure to specify a full URI including the tag
- [YOUR_INVERSE_PROXY_HOST] is the hostname of the inverse proxy to your KFP installation. Recall that you can retrieve the inverse proxy hostname using the below command


To create the Dockerfile describing the TFX image:
```
cat > Dockerfile << EOF
FROM tensorflow/tfx:0.15.0
EOF
```

To build the image and push it to your project's **Container Registry**:
```

gcloud builds submit --timeout 15m --tag ${TFX_IMAGE_URI} .
```

To upload the module file into the GCS location:
```


gsutil cp transform_train.py 
```

The pipeline's DSL retrieves the settings controlling how the pipeline is compiled from the environment variables.To set the environment variables and compile and deploy the pipeline using  **TFX CLI**:

```



tfx pipeline create --engine kubeflow --pipeline_path pipeline_dsl.py --endpoint $KFP_INVERSE_PROXY_HOST
```


```
gcloud container clusters get-credentials [YOUR_GKE_CLUSTER] --zone [YOUR_ZONE]
kubectl describe configmap inverse-proxy-config -n [YOUR_NAMESPACE] | grep "googleusercontent.com"
```

The `tfx pipeline create` command compiled the pipeline's DSL into the KFP package file - `tfx_covertype_classifier_training.tar.gz`. The package file contains the description of the pipeline in the YAML format. If you want to examine the file, extract from the tarball file and use the JupyterLab editor.

```
tar xvf tfx_covertype_classifier_training.tar.gz
```

The name of the extracted file is `pipeline.yaml`.


### Submitting and monitoring pipeline runs

After the pipeline has been deployed, you can trigger and monitor pipeline runs using **TFX CLI** or **KFP UI**.

To submit the pipeline run using **TFX CLI**:
```
tfx run create --pipeline_name tfx_covertype_classifier_training --endpoint $KFP_INVERSE_PROXY_HOST
```

To list all the active runs of the pipeline:
```
tfx run list --pipeline_name tfx_covertype_classifier_training --endpoint $KFP_INVERSE_PROXY_HOST
```

To retrieve the status of a given run:
```
tfx run status --pipeline_name tfx_covertype_classifier_training --run_id [YOUR_RUN_ID] --endpoint $KFP_INVERSE_PROXY_HOST
```
 To terminate a run:
 ```
 tfx run terminate --run_id [YOUR_RUN_ID] --endpoint $KFP_INVERSE_PROXY_HOST
 ```


