FROM pytorch/pytorch:1.4-cuda10.1-cudnn7-runtime
MAINTAINER raku68

ENV PYTHON_MAJOR_VER=3.7 \
    RDKIT_VER=Release_2019_09_3

WORKDIR /workdir
ADD . /workdir

# set proxy
RUN echo "Acquire::http::proxy \"$HTTP_PROXY\";\nAcquire::https::proxy \"$HTTPS_PROXY\";" > /etc/apt/apt.conf
RUN echo "export HTTP_PROXY=\"$HTTP_PROXY\";\nexport HTTPS_PROXY=\"$HTTPS_PROXY\";\nexport http_proxy=\"$HTTPS_PROXY\";\nexport https_proxy=\"$HTTPS_PROXY\";" >> /root/.bashrc

# apt update and install
RUN apt update -y \
    && apt install -y \
       cmake \
       git \
       libboost-dev \
       libboost-iostreams-dev \
       libboost-python-dev \
       libboost-serialization-dev \
       libboost-system-dev \
       libeigen3-dev \
       pkg-config \
       python-cairo \
       wget \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*


# install python packages
RUN pip install -U pip
RUN pip install -r requirements.txt

# set proxy to git
RUN git config --global http.proxy $HTTP_PROXY
RUN git config --global https.proxy $HTTPS_PROXY

# env for rdkit
ENV RDBASE=/opt/conda/lib/python${PYTHON_MAJOR_VER}/site-packages/rdkit \
    LD_LIBRARY_PATH=/opt/conda/lib/python${PYTHON_MAJOR_VER}/site-packages/rdkit/lib:/usr/include/boost:$LD_LIBRARY_PATH \
    PYTHONPATH=$PYTHONPATH:/opt/conda/lib/python${PYTHON_MAJOR_VER}/site-packages/rdkit
    

# build & install rdkit
RUN mkdir -p $RDBASE/.. \
    && cd $RDBASE/.. \
    && git clone https://github.com/rdkit/rdkit.git -b ${RDKIT_VER} \
    && mkdir $RDBASE/build \
    && cd $RDBASE/build \
    && cmake .. \
       -DPy_ENABLE_SHARED=1 \
       -DRDK_INSTALL_INTREE=ON \
       -DRDK_INSTALL_STATIC_LIBS=OFF \
       -DRDK_BUILD_CPP_TESTS=ON \
       -DPYTHON_NUMPY_INCLUDE_PATH="/opt/conda/lib/python${PYTHON_MAJOR_VER}/site-packages/numpy/core/include/" \
    && make && make install && ctest

