FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

# Set "C" locale
ENV LANG=C LC_ALL=C

# Update and install required packages
RUN apt-get update -q && \
	apt-get install -q -y --no-install-recommends \
		build-essential \
		ca-certificates \
		ccache \
		device-tree-compiler \
		file \
		gawk \
		git \
		git-lfs \
		less \
		libncurses5-dev \
		python3 \
		quilt  \
		rsync \
		ssh \
		unzip \
		vim-tiny \
		wget \
	&& \
	apt-get autoremove -q -y && \
	apt-get clean -q -y

ARG UNAME=chef
ARG UID=9999
ARG GID=9999
RUN groupadd -g $GID -o $UNAME
RUN useradd -m -u $UID -g $GID -o -s /bin/bash $UNAME

# Ensure the directories exists
RUN mkdir -p /work && chown -R $UNAME:$UNAME /work

# Mount a volume for persistent storage so we can cache results
VOLUME /work

USER $UNAME
WORKDIR /home/$UNAME

# setup quiltrc to match OpenWrt's recommended settings
# see https://openwrt.org/docs/guide-developer/toolchain/use-patches-with-buildsystem
RUN echo 'QUILT_DIFF_ARGS="--no-timestamps --no-index -p ab --color=auto"' > ~/.quiltrc  && \
	echo 'QUILT_REFRESH_ARGS="--no-timestamps --no-index -p ab"' >> ~/.quiltrc  && \
	echo 'QUILT_SERIES_ARGS="--color=auto"' >> ~/.quiltrc && \
	echo 'QUILT_PATCH_OPTS="--unified"' >> ~/.quiltrc && \
	echo 'QUILT_DIFF_OPTS="-p"' >> ~/.quiltrc
