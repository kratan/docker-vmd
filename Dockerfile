FROM centos:7
LABEL maintainer="andreas.kratzer@kit.edu"

#Set Versions Nvidia Drivers has to be the same as on your docker host
ENV NVIDIA_DRIVER 375.39
ENV NVIDIA_INSTALL http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run

ENV CUDA_VERSION 8.0.61
ENV CUDA_PKG_VERSION 8-0-$CUDA_VERSION-1

ENV VMD_VERSION 1.9.3
ENV VMD_INSTALL vmd-${VMD_VERSION}.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz

COPY cuda.repo /etc/yum.repos.d/cuda.repo
COPY $VMD_INSTALL /tmp/


#adding nvidia rep key
RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 \
	&& curl -fsSL http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA \ 
	&& echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflags=nodocs install epel-release \
    yum -y --setopt=tsflags=nodocs update && \
    yum -y --setopt=tsflag=nodocs install pciutils kbd which sudo && \
    yum -y --setopt=tsflag=nodocs groupinstall "X Window System"


#Set WorkDir to temp
WORKDIR "/tmp"

#Add nvidia driver to current image
RUN curl -o /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run ${NVIDIA_INSTALL} 
RUN sh /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run -a -N --ui=none --no-kernel-module

RUN yum install -y \
        cuda-nvrtc-$CUDA_PKG_VERSION \
        cuda-nvgraph-$CUDA_PKG_VERSION \
        cuda-cusolver-$CUDA_PKG_VERSION \
        cuda-cublas-$CUDA_PKG_VERSION \
        cuda-cufft-$CUDA_PKG_VERSION \
        cuda-curand-$CUDA_PKG_VERSION \
        cuda-cusparse-$CUDA_PKG_VERSION \
        cuda-npp-$CUDA_PKG_VERSION \
        cuda-cudart-$CUDA_PKG_VERSION && \
    ln -s cuda-8.0 /usr/local/cuda && \
    rm -rf /var/cache/yum/*

RUN echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
    ldconfig

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64


#Setup Xpra
RUN rpm --import https://winswitch.org/gpg.asc \
	&& cd /etc/yum.repos.d/ \
	&& yum install -y curl \
	&& curl -O https://winswitch.org/downloads/CentOS/winswitch.repo \
	&& yum -y install xpra perl


#extract VMD
RUN tar xzfv /tmp/${VMD_INSTALL} -C /


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN yum clean all && rm -Rf /tmp/*

WORKDIR "/vmd-${VMD_VERSION}"


CMD ["/entrypoint.sh"]
