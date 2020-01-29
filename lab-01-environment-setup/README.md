# Setting up an MLOps environment on GCP.

The labs in this repo are designed to run in a reference MLOps environment. The environment is configured to support effective development and operationalization of production grade ML workflows.

![Reference topolgy](/images/lab_300.png)

The core services in the environment are:
- AI Platform Notebooks - ML experimentation and development
- AI Platform Training - scalable, serverless model training
- AI Platform Prediction - scalable, serverless model serving
- Dataflow - distributed data processing
- BigQuery - analytics data warehouse
- Cloud Storage - unified object storage
- TensorFlow Extended/Kubeflow Pipelines (TFX/KFP) - machine learning pipelines
- Cloud SQL - machine learning metadata  management
- Cloud Build - CI/CD
    
In this lab, you will create an **AI Platform Notebook** instance using a custom container image optimized for TFX/KFP development. In the **lab-02-environment-kfp** lab, you will provision a lightweight deployment of **Kubeflow Pipelines**.

In the reference environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

Although you can run the below commands from any workstation configured with *Google Cloud SDK*, the following instructions have been tested on GCP [Cloud Shell](https://cloud.google.com/shell/).

## Enabling the required cloud services

In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled in the project hosting an MLOps environment:

1. Compute Engine
1. Container Registry
1. AI Platform Training and Prediction
1. IAM
1. Dataflow
1. Kubernetes Engine
1. Cloud SQL
1. Cloud SQL Admin
1. Cloud Build
1. Cloud Resource Manager

Use [GCP Console](https://console.cloud.google.com/) or `gcloud` command line interface in [Cloud Shell](https://cloud.google.com/shell/docs/) to [enable the required services](https://cloud.google.com/service-usage/docs/enable-disable) . 

To enable the required services using `gcloud`:
1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)

2. Execute the below command.
```
gcloud services enable cloudbuild.googleapis.com \
	container.googleapis.com \
	cloudresourcemanager.googleapis.com \
	iam.googleapis.com \
	containerregistry.googleapis.com \
	containeranalysis.googleapis.com \
	ml.googleapis.com \
	sqladmin.googleapis.com \
	dataflow.googleapis.com \
	automl.googleapis.com
```

3. After the services are enabled, [grant the Cloud Build service account the Project Editor role](https://cloud.google.com/cloud-build/docs/securing-builds/set-service-account-permissions).


## Creating an **AI Platform Notebooks** instance

You will use a custom container image configured for KFP/TFX development as an environment for your instance. The image is a derivative of the standard TensorFlow 1.15  [AI Deep Learning Containers](https://cloud.google.com/ai-platform/deep-learning-containers/docs/) image.

### Creating the custom image's Dockerfile:

1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)

2. Create a working folder in your `home` directory
```
cd
mkdir lab-01-workspace
cd lab-01-workspace
```

3. Create Dockerfile 
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/tf-cpu.1-15
RUN apt-get update -y && apt-get -y install kubectl
RUN cd /usr/local/bin \
&& wget https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.3.0/kustomize_v3.3.0_linux_amd64.tar.gz \
&& tar xvf kustomize_v3.3.0_linux_amd64.tar.gz \
&& rm kustomize_v3.3.0_linux_amd64.tar.gz \
&& wget https://releases.hashicorp.com/terraform/0.12.19/terraform_0.12.19_linux_amd64.zip \
&& unzip terraform_0.12.19_linux_amd64.zip
RUN pip install -U six==1.12 apache-beam==2.16 pyarrow==0.14.0 tfx-bsl==0.15.1 \
&& pip install -U tfx==0.15 \
&& pip install -U tensorboard \
&& pip install https://storage.googleapis.com/ml-pipeline/release/0.1.36/kfp.tar.gz
EOF
```

### Building the image and pushing it to your project's **Container Registry**

```
PROJECT_ID=$(gcloud config get-value core/project)
IMAGE_NAME=mlops-dev
TAG=TF115-TFX015-KFP136

IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"

gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```

### Provisioning an AI Platform notebook instance

To provision an instance of **AI Platform Notebooks** using the custom image, follow the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container). In the **Docker container image** field, enter the full name of the image (including the tag) you created in the previous step.


### Assigning roles to the default Compute Engine account

When using the instance, the GCP services are accessed using the [Compute Engine default service account](https://cloud.google.com/compute/docs/access/service-accounts). For the labs to work this account needs to have **Project/Editor**, **Kubernetes Engine/Kubernetes Engine Admin**, and **IAM/Security Admin** permissions in your project. The **Project/Editor** role is granted to the account by default.

To grant the **IAM/Security Admin** and **Kubernetes Engine/Kubernetes Engine Admin** roles follow [this instructions](https://cloud.google.com/iam/docs/granting-roles-to-service-accounts). Recall that your projects' **Compute Engine default service account** is
```
[PROJECT_NUMBER]-compute@developer.gserviceaccount.com
```

### Accessing JupyterLab IDE

You will use [JupyterLab](https://jupyter.org/) IDE as your primary development environment for most of the labs in this repo, including **lab-02-environment-kfp** that guides you through the installation of a lightweight deployment of Kubeflow Pipelines.

After the instance is created, you can connect to [JupyterLab](https://jupyter.org/) IDE by clicking the *OPEN JUPYTERLAB* link.

