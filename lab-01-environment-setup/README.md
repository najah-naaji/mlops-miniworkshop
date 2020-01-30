# Setting up a lab environment.

The labs in this repo are designed to run in a simplified MLOps environment. 

![Reference topolgy](/images/lab-env.png)

The core services in the environment are:
- **AI Platform Notebooks** - your development experimentation environment
- **Cloud Storage** - a GCS bucket for pipeline artifacts
- **Kubeflow Pipelines** - a lightweight deployment of Kubeflow Pipelines on GKE hosting ML Pipelines and ML Metadata services. GKE will also be used as a primary execution environment for KFP and TFX components.
- **Cloud Build** - CI/CD
- **Container Registry** - a registry for container images encapsulating pipeline components
    
In the lab environment, all services are provisioned in the same [Google Cloud Project](https://cloud.google.com/storage/docs/projects). Before proceeding make sure that your account has access to the project and is assigned to the **Owner** or **Editor** role.

Although you can run the below commands from any workstation configured with *Google Cloud SDK*, the following instructions have been tested on GCP [Cloud Shell](https://cloud.google.com/shell/).

## Enabling the required cloud services

In addition to the [services enabled by default](https://cloud.google.com/service-usage/docs/enabled-service), the following additional services must be enabled in the project hosting your lab environment:

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
PROJECT_ID=[YOUR_PROJECT_ID]

gcloud config set project $PROJECT_ID
gcloud services enable \
cloudbuild.googleapis.com \
container.googleapis.com \
cloudresourcemanager.googleapis.com \
iam.googleapis.com \
containerregistry.googleapis.com \
containeranalysis.googleapis.com \
ml.googleapis.com 
```

3. After the services are enabled, [grant the Cloud Build service account the Project Editor role](https://cloud.google.com/cloud-build/docs/securing-builds/set-service-account-permissions).


## Creating an **AI Platform Notebooks** instance

You will be using an **AI Platform Notebook** instance, configured with a custom container image optimized for TFX/KFP development, as your primary development/experimentation environment 

The image is a derivative of the standard TensorFlow 2.0  [AI Deep Learning Containers](https://cloud.google.com/ai-platform/deep-learning-containers/docs/) image.

### Creating the custom image's Dockerfile:

1. Start GCP [Cloud Shell](https://cloud.google.com/shell/docs/)

2. Create a working folder in your `home` directory
```
cd
mkdir lab-setup
cd lab-setup
```

3. Create Dockerfile 
```
cat > Dockerfile << EOF
FROM gcr.io/deeplearning-platform-release/tf2-cpu.2-0:m39
RUN apt-get update -y && apt-get -y install kubectl
RUN pip install -U six==1.12 apache-beam==2.16 pyarrow==0.14.0 tfx-bsl==0.15.1 \
&& pip install -U tfx==0.15 \
&& pip install -U tensorboard \
&& pip install https://storage.googleapis.com/ml-pipeline/release/0.1.36/kfp.tar.gz
EOF
```

### Building the image and pushing it to your project's **Container Registry**

```
PROJECT_ID=[YOUR_PROJECT_ID]

gcloud config set project $PROJECT_ID
IMAGE_NAME=mlops-dev
TAG=TFX015-KFP136
IMAGE_URI="gcr.io/${PROJECT_ID}/${IMAGE_NAME}:${TAG}"
gcloud builds submit --timeout 15m --tag ${IMAGE_URI} .
```

### Provisioning an AI Platform notebook instance

To provision an instance of **AI Platform Notebooks** using the custom image, follow the  [instructions in AI Platform Notebooks Documentation](https://cloud.google.com/ai-platform/notebooks/docs/custom-container). In the **Docker container image** field, enter the full name of the image (including the tag) you created in the previous step.


### Accessing JupyterLab IDE

You will use [JupyterLab](https://jupyter.org/) IDE as your primary development environment for most of the labs in this repo, including **lab-02-environment-kfp** that guides you through the installation of a lightweight deployment of Kubeflow Pipelines.

After the instance is created, you can connect to [JupyterLab](https://jupyter.org/) IDE by clicking the *OPEN JUPYTERLAB* link.

## Provisionining Kubeflow Pipelines environment

In this step you provision a lightweight deployment of Kubeflow Pipelines on Google Kubernetes Cluster (GKE).

![KFP](/images/kfp-deployment.png)

In comparison to a full **Kubeflow** installation, in the lightweight deployment only ML pipeline and metadata services are deployed to the GKE cluster. The services are configured to use the GKE hosted MySQL instance as Metadata store and [Minio](https://min.io/?gclid=EAIaIQobChMI_4ij7Ymq5wIVwRd9Ch0H2Q31EAAYASAAEgKk2PD_BwE) for artifact storage. External clients use Google managed Inverting Proxy to interact with the KFP services.

Provisioning of the underlying infrastructure (GKE, service accounts, etc) and installing of KFP have been automated with **Terraform** and **Google Cloud SDK**.

To provision KFP environment

1. Open **Cloud Shell**
2. Clone this repo under the `home` folder.
```
cd /
git clone https://github.com/jarokaz/mlops-miniworkshop.git
cd mlops-miniworkshop/lab-01-environment-setup
```

3. Start installation
```
./install.sh [PROJECT_ID] [PREFIX]
```
Where 
- `[PROJECT_ID]` - your project ID
- `[PREFIX]` - the prefix that will be added to the names of the provisioned resources

The script installs GKE to the `us-central1-a` zone, which is a recommended location. If you need to install GKE to some other zone, specify the zone name as the last argument.

4. Review the logs generated by the script for any errors.

## Accessing KFP UI

After the installation completes, you can access the KFP UI from the following URL. You may need to wait a few minutes before the URL is operational.

```
echo "https://"$(kubectl describe configmap inverse-proxy-config -n [NAMESPACE] | grep "googleusercontent.com")
```

