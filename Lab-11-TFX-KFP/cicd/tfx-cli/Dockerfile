FROM tensorflow/tfx:0.15.0
RUN RELEASE=0.1.34 \
&& pip install google-resumable-media==0.4.1 https://storage.googleapis.com/ml-pipeline/release/$RELEASE/kfp.tar.gz 

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

ENTRYPOINT ["tfx"]
