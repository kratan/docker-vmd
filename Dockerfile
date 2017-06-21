FROM centos:7
LABEL maintainer="andreas.kratzer@kit.edu"

#Driver
ENV NVIDIA_DRIVER 381.22
ENV NVIDIA_INSTALL http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run

#Cuda
ENV CUDA_VERSION 8.0.61
ENV CUDA_PKG_VERSION 8-0-$CUDA_VERSION-1


#adding nvidia rep key
RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

COPY cuda.repo /etc/yum.repos.d/cuda.repo

WORKDIR "/tmp"

#Add nvidia driver to current image
RUN curl -o /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run ${NVIDIA_INSTALL}
RUN sh /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run -a -N --ui=none --no-kernel-module

#Cuda
RUN rpm --rebuilddb \
        && yum install -y \
         cuda-nvrtc-$CUDA_PKG_VERSION \
         cuda-nvgraph-$CUDA_PKG_VERSION \
         cuda-cusolver-$CUDA_PKG_VERSION \
         cuda-cublas-8-0-8.0.61.1-1 \
         cuda-cufft-$CUDA_PKG_VERSION \
         cuda-curand-$CUDA_PKG_VERSION \
         cuda-cusparse-$CUDA_PKG_VERSION \
         cuda-npp-$CUDA_PKG_VERSION \
         cuda-cudart-$CUDA_PKG_VERSION \
    && ln -s cuda-8.0 /usr/local/cuda \
    && rm -rf /var/cache/yum/*

RUN echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && \
    ldconfig

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64


#Driver Xorg
RUN yum install -y  \
        epel-release \
        pciutils kbd which sudo policycoreutils \
        && yum groupinstall -y "X Window System"


#Setup Xpra
RUN rpm --rebuilddb \
        && rpm --import https://winswitch.org/gpg.asc \
        && cd /etc/yum.repos.d/ \
        && yum install -y curl \
        && curl -O https://winswitch.org/downloads/CentOS/winswitch.repo \
        && yum -y install xpra perl


#--VMD--#
ENV VMD_VERSION=1.9.3
ENV VMD_INSTALL=http://www.ks.uiuc.edu/Research/vmd/vmd-${VMD_VERSION}/files/final/vmd-${VMD_VERSION}.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz


#Download + extract VMD
RUN curl -o /tmp/vmd-${VMD_VERSION}.tar.gz ${VMD_INSTALL} \
        && tar xzfv /tmp/vmd-${VMD_VERSION}.tar.gz -C /

#RUN curl -SL $VMD_INSTALL | tar xJC /

#Download Demos
RUN curl -o /tmp/vmd-demos.tar.gz http://www.ks.uiuc.edu/Training/Tutorials/vmd/vmd-tutorial-files.tar.gz \
	&& mkdir /vmd-demos \
        && tar xzfv /tmp/vmd-demos.tar.gz -C /vmd-demos

RUN yum clean all && rm -Rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR "/vmd-${VMD_VERSION}"

CMD ["/entrypoint.sh"]

