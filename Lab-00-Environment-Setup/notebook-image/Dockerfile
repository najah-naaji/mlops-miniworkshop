FROM gcr.io/deeplearning-platform-release/base-cpu
SHELL ["/bin/bash", "-c"]
RUN apt-get update -y && apt-get -y install kubectl
RUN conda create -n tfx python=3.6 && source activate tfx \
&& pip install -U httplib2==0.12.0 tensorflow==1.15 tensorflow-serving-api==1.15 \
&& pip install -U tfx==0.15.0rc0 \ 
&& RELEASE=0.1.33 \
&& pip install https://storage.googleapis.com/ml-pipeline/release/$RELEASE/kfp.tar.gz  \
&& python -m ipykernel install --name tfx 
