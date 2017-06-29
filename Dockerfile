FROM centos:7
LABEL maintainer="andreas.kratzer@kit.edu"

#Driver
ENV NVIDIA_DRIVER=381.22 
ENV NVIDIA_INSTALL=http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_DRIVER}/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run

#Cuda
ENV CUDA_VERSION=8.0.61 
ENV CUDA_PKG_VERSION=8-0-$CUDA_VERSION-1


#adding nvidia rep key
#RUN NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
#    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
#    echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

#COPY cuda.repo /etc/yum.repos.d/cuda.repo

WORKDIR "/tmp"

#Add nvidia driver to current image
RUN curl -o /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run ${NVIDIA_INSTALL} \
	&& sh /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run -a -N --ui=none --no-kernel-module \
	&& echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf \
	&& echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH} LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64


#Basic Xorg Installation + SSH
RUN yum install -y  \
        epel-release \
        pciutils \
	kbd \
	which \
	sudo \
	policycoreutils \
	openssh-server \
	make \
	perl \
        && yum groupinstall -y "X Window System"


#VMD Install
ENV VMD_VERSION=1.9.3
ENV VMD_INSTALL=http://www.ks.uiuc.edu/Research/vmd/vmd-${VMD_VERSION}/files/final/vmd-${VMD_VERSION}.bin.LINUXAMD64-CUDA8-OptiX4-OSPRay111p1.opengl.tar.gz
RUN curl -o /tmp/vmd-${VMD_VERSION}.tar.gz ${VMD_INSTALL} \
        && tar xzfv /tmp/vmd-${VMD_VERSION}.tar.gz -C /


#Download Demos
RUN curl -o /tmp/vmd-demos.tar.gz http://www.ks.uiuc.edu/Training/Tutorials/vmd/vmd-tutorial-files.tar.gz \
	&& mkdir /vmd-demos \
        && tar xzfv /tmp/vmd-demos.tar.gz -C /vmd-demos \
	&& chmod 0666 -R /vmd-demos


#install tini
ENV TINI_VERSION v0.14.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/local/bin/tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}‡P/tini.asc /tini.asc
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
	&& gpg --verify /tini.asc
	&& chmod +x /usr/local/bin/tini

#install virtualgl and cleanup
ENV VIRTUALGL_VERSION=2.5.2
RUN curl -sSL https://kent.dl.sourceforge.net/project/virtualgl/${VIRTUALGL_VERSION}/VirtualGL-${VIRTUALGL_VERSION}.x86_64.rpm -o /tmp/VirtualGL-${VIRTUALGL_VERSION}.x86_64.rpm \
	&& rpm --rebuilddb \
	&& yum -y --nogpgcheck install /tmp/VirtualGL-${VIRTUALGL_VERSION}.x86_64.rpm \
	&& /opt/VirtualGL/bin/vglserver_config -config +s +f -t \
	&& yum clean all && rm -Rf /tmp/*



COPY entrypoint.d/ /entrypoint.d/
COPY entrypoint.sh /
WORKDIR "/vmd-${VMD_VERSION}"

ENTRYPOINT ["/entrypoint.sh"]

