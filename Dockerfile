FROM nvcr.io/nvidia/cuda:11.6.2-cudnn8-devel-ubuntu20.04
MAINTAINER da21510 <da21510@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends apt-utils && \
    apt install -y net-tools && \
    apt install -y iputils-ping && \
    apt install -y vim nano && \
    apt install -y openssh-server && \
    apt clean
### Python3.8
RUN apt install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt update -y && \
    apt install python3.8 -y && \
    apt clean && \
    cd /usr/bin/ ; rm python3 ; ln -s python3.8 python3

### Pip3 && pipenv

RUN apt install -y python3-pip && \
    apt clean
RUN pip3 install -U pip
RUN pip3 install -U setuptools
RUN pip3 install pipenv

### Build Env (Pytorch version)
ENV WORKON_HOME /envs
RUN mkdir /envs

ENV PIPENV_TIMEOUT 9999
ENV PIPENV_INSTALL_TIMEOUT 9999

WORKDIR /envs
RUN mkdir pytorch
COPY pytorch_version.txt pytorch/requirements.txt
WORKDIR pytorch
RUN pipenv install --python 3.8 -r requirements.txt && \
    rm -rf ~/.cache

### Build Env (Tensorflow_keras version)
WORKDIR /envs
RUN mkdir tf_keras
COPY tf_keras_version.txt tf_keras/requirements.txt
WORKDIR tf_keras
RUN pipenv install --python 3.8 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache

WORKDIR /envs

### R for 4.0.1

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" && \
    apt update -y && \
    apt install -y r-recommended r-base && \
    apt clean

### oracle JAVA 8
COPY jdk-8u333-linux-x64.tar.gz /opt
WORKDIR /opt
RUN tar zxvf jdk-8u333-linux-x64.tar.gz
RUN rm jdk-8u333-linux-x64.tar.gz

ENV JAVA_HOME /opt/jdk1.8.0_333
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH=${JAVA_HOME}/bin:$PATH
COPY profile /etc/profile

### R packages
RUN R CMD javareconf
RUN apt install ocl-icd-opencl-dev libxml2-dev libgmp3-dev opencl-headers libssl-dev -y
RUN ln -s /usr/lib/x86_64-linux-gnu/libOpenCL.so.1 /usr/lib/libOpenCL.so
RUN Rscript -e "install.packages(c('xgboost', 'readxl', 'xlsx', 'tidyverse', 'klaR', 'ClusterR', 'pracma', 'fields', 'filehashSQLite', 'filehash', 'LatticeKrig', 'spam', 'RSpectra', 'filematrix', 'autoFRK', 'Metrics', 'adabag', 'neuralnet', 'caTools', 'nnet', 'caret', 'ada', 'randomForest', 'inTrees', 'UBL', 'cvTools', 'gdata', 'moments', 'zoo', 'parcor', 'MASS', 'chemometrics', 'rpart', 'e1071'))"

### change permission and create group for user

RUN groupadd imbduser && \
    chown -R root:imbduser /envs && \
    chmod -R 770 /envs

WORKDIR /envs

ENTRYPOINT service ssh restart && bash
