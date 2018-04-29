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
        python-scipy && \
    rm -rf /var/lib/apt/lists/*

#RUN cd /usr/lib/x86_64-linux-gnu && \
#    sudo ln -s libhdf5_serial.so.8.0.2 libhdf5.so && \
#    sudo ln -s libhdf5_serial_hl.so.8.0.2 libhdf5_hl.so


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
RUN cp Makefile.config.example Makefile.config && \
    mkdir build && cd build && \
    cmake -DUSE_NCCL=1 .. && \
    WITH_PYTHON_LAYER=1 make -j"$(nproc)" && make pycaffe
 

# Download the CUDA drivers from https://developer.nvidia.com/rdp/cudnn-archive and place it here  :
#ADD cudnn-7.0-linux-x64-v3.0.8-prod.tgz /
#WORKDIR /cuda
#RUN cp -P include/cudnn.h /usr/include
#RUN cp -P lib64/libcudnn* /usr/lib/x86_64-linux-gnu/


# Set the environment variables so that the paths are correctly configured
ENV CAFFE_ROOT=$CTPN_ROOT/CTPN/caffe
ENV PYCAFFE_ROOT=$CTPN_ROOT/CTPN/caffe/python
ENV PYTHONPATH=$PYCAFFE_ROOT:$PYTHONPATH 
ENV PATH=$CTPN_ROOT/CTPN/caffe/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CTPN_ROOT/CTPN/caffe/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# To make sure the python layer builds - Need to figure out a cleaner way to do this.
RUN cp $CTPN_ROOT/CTPN/src/layers/* $CTPN_ROOT/CTPN/caffe/src/caffe/layers/ && \
    cp $CTPN_ROOT/CTPN/src/*.py $CTPN_ROOT/CTPN/caffe/src/caffe/ && \
    cp -r $CTPN_ROOT/CTPN/src/utils $CTPN_ROOT/CTPN/caffe/src/caffe/

# Install Opencv - 2.4.12 :

RUN cd ~ && \
    mkdir -p ocv-tmp && \
    cd ocv-tmp && \
    wget https://github.com/Itseez/opencv/archive/2.4.12.zip  && \
    unzip 2.4.12.zip && \
    cd opencv-2.4.12 && \
    mkdir release && \
    cd release && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D BUILD_PYTHON_SUPPORT=ON \
          .. && \
    make -j8 && \
    make install && \
    rm -rf ~/ocv-tmp

WORKDIR $CTPN_ROOT/CTPN
RUN make -j8

CMD ["/bin/bash"]
