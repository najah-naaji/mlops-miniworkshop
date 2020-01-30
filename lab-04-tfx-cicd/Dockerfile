FROM gcr.io/deeplearning-platform-release/tf2-cpu.2-0:m39
RUN pip install -U six==1.12 apache-beam==2.16 pyarrow==0.14.0 tfx-bsl==0.15.1 && pip install -U tfx==0.15 && pip install -U https://storage.googleapis.com/ml-pipeline/release/0.1.36/kfp.tar.gz 

ENTRYPOINT ["tfx"]
