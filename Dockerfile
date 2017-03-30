FROM ubuntu:xenial-20170214 
LABEL maintainer="andreas.kratzer@kit.edu"
 

#Environmental Stuff
ENV DEBIAN_FRONTEND=noninteractive 
ENV INITRD=no PATH=/usr/local/cuda/bin:${PATH}

ENV NVIDIA_VER=375.39 
ENV NVIDIA_INSTALL=http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VER}/NVIDIA-Linux-x86_64-${NVIDIA_VER}.run


# Install main Stuff
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
    && apt-get update \
    && apt-get install --no-install-recommends -y x-window-system \
	binutils \
	mesa-utils \
        module-init-tools \
        mesa-utils \
	git \
	gnupg2 \
	build-essential \
	curl \
	pkg-config \
	ca-certificates \
	python-netifaces \
	wget \
	python-software-properties \
	software-properties-common	
	

#Setup Meshlab Repo
RUN add-apt-repository ppa:zarquon42/meshlab \
	&& apt-get update

#Setup Xpra Repo
RUN curl https://winswitch.org/gpg.asc | apt-key add - \
	&& echo "deb http://winswitch.org/ xenial main" > /etc/apt/sources.list.d/winswitch.list \
	&& apt-get update \
	&& apt-get upgrade --no-install-recommends -y

	

#Setup Xpra + Meshlab
RUN apt-get install --no-install-recommends -y \
	xpra \
	websockify \
	python-dbus \
	dbus \
	dbus-x11 \
	meshlab


#Add nvidia driver to current image
RUN echo /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run ${NVIDIA_INSTALL}
RUN curl -o /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run ${NVIDIA_INSTALL} \
	&& sh /tmp/NVIDIA-Linux-x86_64-${NVIDIA_DRIVER}.run -a -N --ui=none --no-kernel-module


# Create the directory needed to run the dbus daemon and Xpra
RUN mkdir /var/run/dbus && mkdir /var/run/xpra \
	&& chown -R root:xpra /var/run/xpra && chmod 0775 -R /var/run/xpra


#cleanup
RUN apt-get clean -y \
	&& apt-get autoclean -y \
	&& apt-get autoremove -y \
	&& rm -rf /usr/share/locale/*  \
	&& rm -rf /var/cache/debconf/*-old \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /usr/share/doc/* \
	rm -rf /tmp/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 10011

CMD ["/entrypoint.sh"]
