### nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04
FROM docker.io/nvidia/cuda@sha256:217134b60289ced62b47463be32584329baf35cb55a9ccda6626b91bd59803be
MAINTAINER da21510 <da21510@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y --no-install-recommends apt-utils && \
    apt install -y net-tools && \
    apt install -y iputils-ping && \
    apt install -y vim nano && \
    apt install -y openssh-server && \
    apt install -y git zip htop screen && \    
    apt install -y libgl1 && \    
    apt clean

### Pip3 && pipenv
RUN apt install -y python3-pip && \
    apt-get install -y python3-apt && \
    apt clean
RUN pip3 install -U pip
RUN pip3 install -U setuptools
RUN pip3 install pipenv

ENV WORKON_HOME /envs
RUN mkdir /envs

ENV PIPENV_TIMEOUT 9999
ENV PIPENV_INSTALL_TIMEOUT 9999

### Build Env (Tensorflow_keras)
WORKDIR /envs
RUN mkdir tf_keras
COPY tf_keras_version.txt tf_keras/Pipfile
WORKDIR tf_keras
RUN pipenv install --python 3.10 --skip-lock && \
    rm -rf ~/.cache

### Build Env (Pytorch version)
WORKDIR /envs
RUN mkdir pytorch
COPY pytorch_version.txt pytorch/Pipfile
WORKDIR pytorch
RUN pipenv install --python 3.10 --skip-lock && \
    rm -rf ~/.cache

### Build Env (Yolov7 version)
WORKDIR /envs
RUN git clone https://github.com/WongKinYiu/yolov7.git --depth 1
WORKDIR yolov7
RUN git fetch --unshallow && \
    pipenv install --verbose --python 3.10 -r requirements.txt --skip-lock && \
    rm -rf ~/.cache && \
    wget -4 https://github.com/WongKinYiu/yolov7/releases/download/v0.1/yolov7.pt

WORKDIR /envs

### oracle JAVA 8
COPY jdk-8u371-linux-x64.tar.gz /opt
WORKDIR /opt
RUN tar zxvf jdk-8u371-linux-x64.tar.gz
RUN rm jdk-8u371-linux-x64.tar.gz

ENV JAVA_HOME /opt/jdk1.8.0_371
ENV JRE_HOME=${JAVA_HOME}/jre
ENV CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
ENV PATH=${JAVA_HOME}/bin:$PATH
COPY profile /etc/profile

### Build Env (R version)
### R dependence
WORKDIR /envs
RUN apt install -y liblzma-dev libbz2-dev libicu-dev libxml2-dev libssl-dev libcurl4-openssl-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev gfortran liblapack-dev libblas-dev libgmp-dev libudunits2-dev gdal-bin libgdal-dev && \
    apt clean
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | gpg --dearmor -o /usr/share/keyrings/r-project.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" | tee -a /etc/apt/sources.list.d/r-project.list
RUN apt update && \
    apt install -y --no-install-recommends r-base
RUN R CMD javareconf
COPY r_requirement.txt .
COPY installPackage.R .
RUN Rscript installPackage.R

### change permission and create group for user

RUN groupadd imbduser && \
    chown -R root:imbduser /envs && \
    chmod -R 770 /envs

WORKDIR /envs

ENTRYPOINT service ssh restart && /bin/bash
