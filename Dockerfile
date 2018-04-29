FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu14.04
MAINTAINER Varun Suresh <fab.varun@gmail.com>

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        zip \
        unzip \
        libdc1394-22-dev \
        libdc1394-22 \
        libdc1394-utils \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libhdf5-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-opencv \
        python-numpy \
        python-pip \
        python-setuptools \
        python-h5py \
        python-scipy && \
    rm -rf /var/lib/apt/lists/*


ENV CTPN_ROOT=/opt
WORKDIR $CTPN_ROOT

# Missing "packaging" package
RUN pip install --upgrade pip
RUN pip install packaging

RUN git clone --depth 1 https://github.com/gayathrimahalingam/CTPN.git
WORKDIR $CTPN_ROOT/CTPN/caffe

# Missing "packaging" package
RUN pip install --upgrade pip && \
    pip install packaging

RUN cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    git clone https://github.com/NVIDIA/nccl.git && \
    cd nccl && make -j install && cd .. && rm -rf nccl 

WORKDIR $CTPN_ROOT/CTPN/caffe


CMD ["/bin/bash"]
