FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
	tree \
        apt-transport-https \
        bc \
        bridge-utils \
        build-essential \
        bzip2 \
        ca-certificates \
        cpio \
        curl \
        dialog \
        dnsmasq \
        git \
        gnupg-agent \
        iptables \
        jq \ 
        libaio-dev \
        libssl-dev \
        libelf-dev \
        libguestfs-tools \
        libicu-dev \
        libncurses5-dev \
        libncursesw5 \
        moreutils \
        ncurses-base \
        ncurses-bin \
        python \
        python3-aiohttp \
        rsync \
        sed \
        software-properties-common \
        sshpass \
        subversion \
        sudo \
        unzip \
        vim \
        wget

RUN mkdir -p /build && \
    mkdir -p /.buildroot-ccache && \
    mkdir -p /home && \
    mkdir -p /.cache && \
    chmod 777 /build && \
    chmod 777 /home && \
    chmod 777 /.buildroot-ccache && \
    chmod 777 /.cache 

WORKDIR /build
