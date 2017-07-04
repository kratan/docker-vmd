FROM kratan/bwvisu-xpra:centos
LABEL maintainer="andreas.kratzer@kit.edu"


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



COPY entrypoint.d/ /entrypoint.d/
COPY entrypoint.sh /
WORKDIR "/vmd-${VMD_VERSION}"

ENTRYPOINT ["/entrypoint.sh"]

