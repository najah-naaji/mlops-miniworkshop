# Orchestrating model training and deployment with TFX on KFP

In this lab you will develop, deploy and run a TFX pipeline that uses Kubeflow Pipelines as an orchestrator.


## Lab scenario

You will be working with the [Covertype Data Set](https://github.com/jarokaz/mlops-labs/blob/master/datasets/covertype/README.md) dataset. 

The pipeline implements a typical TFX workflow as depicted on the below diagram:

![Lab 03 diagram](../images/lab-03-diagram.png).

The source data in a CSV file format is in the GCS bucket.

The TFX components run in containers orchestrated by Kubeflow Pipelines.


## Lab setup

Before proceeding with the lab, you must set up an **AI Platform Notebooks** instance and a **KFP** environment as detailed in `lab-01-environment-setup`.

## Lab Exercises

Follow the instructor who will walk you through the lab. The high level summary of the lab flow is as follows:

### Understanding the pipeline's DSL.

The pipeline uses the [tensorflow/tfx:0.15.0 image](https://hub.docker.com/r/tensorflow/tfx), as a runtime execution environment for the pipeline's components. 

The `Transform` and `Train` components are configured to retrieve the module file with the preprocessing and training code from the folder in the artifact store GCS bucket.

All code executes in containers on the GKE cluster.


### Building and deploying the pipeline


Start by configuring your environment settings:
```
export PROJECT_ID=[YOUR_PROJECT_ID]
export ARTIFACT_STORE_URI=[YOUR_ARTIFACT_STORE_URI]
export KFP_INVERSE_PROXY_HOST=[YOUR_INVERSE_PROXY_HOST]
```

Where 
- [YOUR_ARTIFACT_STORE_URI] is the URI of the bucket created during the KFP environment setup - `gs://[PREFIX]-artifact-store`
- [YOUR_TFX_IMAGE_URI] is the URI of the image you created in the previous step. Make sure to specify a full URI including the tag
- [YOUR_INVERSE_PROXY_HOST] is the hostname of the inverse proxy to your KFP installation. 


You can retrieve the inverse proxy hostname from the GKE Console or using the below command:

```
gcloud container clusters get-credentials [YOUR_GKE_CLUSTER_NAME] --zone [YOUR_ZONE]
kubectl describe configmap inverse-proxy-config -n kubeflow | grep "googleusercontent.com"
```

Where:
- [YOUR_GKE_CLUSTER_NAME] is the name of your GKE cluster in the `[PREFIX]-cluster` format.

Upload the module file into the GCS location:
```
export MODULE_FILE_URI=${ARTIFACT_STORE_URI}/modules/transform_train.py

gsutil cp transform_train.py $MODULE_FILE_URI
```

Compile the pipeline.

```
export PIPELINE_NAME=tfx_covertype_classifier_training
export TRAINED_MODEL_URI=${ARTIFACT_STORE_URI}/trained_models/$PIPELINE_NAME
export DATA_ROOT_URI=gs://workshop-datasets/covertype/full
export TFX_IMAGE_URI=tensorflow/tfx:0.15.0

tfx pipeline create --engine kubeflow --pipeline_path pipeline_dsl.py --endpoint $KFP_INVERSE_PROXY_HOST
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
tfx run create --pipeline_name $PIPELINE_NAME --endpoint $KFP_INVERSE_PROXY_HOST
```

To list all the active runs of the pipeline:
```
tfx run list --pipeline_name $PIPELINE_NAME --endpoint $KFP_INVERSE_PROXY_HOST
```

To retrieve the status of a given run:
```
tfx run status --pipeline_name tfx_covertype_classifier_training --run_id [YOUR_RUN_ID] --endpoint $KFP_INVERSE_PROXY_HOST
```
 To terminate a run:
 ```
 tfx run terminate --run_id [YOUR_RUN_ID] --endpoint $KFP_INVERSE_PROXY_HOST
 ```


