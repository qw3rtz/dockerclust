###############################################################################
# check and setup environment
###############################################################################
ifeq ($(BUILDROOT_VERSION),)
	$(error BUILDROOT_VERSION not set)
else
	BUILDROOT_FILE := buildroot-${BUILDROOT_VERSION}
endif

# defaulting to rpi4 if not set
ifeq ($(TARGET_PLATFORM),)
	TARGET_PLATFORM := rpi4
endif

BUILD_CONTAINER ?= buildroot-builder
USER_ID ?= $(shell id -u)
GROUP_ID ?= $(shell id -g)
NAME ?= dockerclust
IMAGE_FILE := $(NAME)-$(VERSION)
ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
BR2_DL_DIR ?= $(ROOT_DIR)/dl

###############################################################################
# USE Docker or native build 
###############################################################################
docker-%: build_img
	docker run -ti \
	   --user $(USER_ID):$(GROUP_ID) \
	   -v /etc/passwd:/etc/passwd:ro \
	   -v /etc/group:/etc/group:ro \
	   -v $(ROOT_DIR)/:/build/ \
	   -e http_proxy \
	   -e https_proxy \
	   -e ftp_proxy \
	   -e BUILDROOT_VERSION \
	   -e BUILDROOTTARGET \
	   -e DEFCONFIG \
	   -e VERSION \
	   -e NAME \
	   -e IMAGE_FILE \
	   --rm $(BUILD_CONTAINER) \
	   make $*

###############################################################################

EXTERNAL_PATH := $(ROOT_DIR)/project/$(TARGET_PLATFORM)

.DEFAULT_GOAL := help
###############################################################################
# Overwrite Make command 
###############################################################################

MAKE_CMD := make \
	 O=$(ROOT_DIR)/output/$(TARGET_PLATFORM) \
	 V=0 \
	 BR2_EXTERNAL=$(EXTERNAL_PATH) \
	 VERSION=$(VERSION) \
	 NAME=$(NAME) \
	 IMAGE_FILE=$(IMAGE_FILE) \
	 BR2_DL_DIR=$(BR2_DL_DIR) \
	 -C $(ROOT_DIR)/buildroot

###############################################################################
# Targets:
###############################################################################
.PHONY: help
help:
	@echo "Targets:"
	@echo "  [docker-]help                       show this help."
	@echo "  [docker-]build                      builds image."
	@echo ""
	@echo "  [docker-]menuconfig"
	@echo "  [docker-]busybox-menuconfig"
	@echo "  [docker-]linux-menuconfig"
	@echo ""
	@echo "  [docker-]clean                      remove build files."
	@echo "  [docker-]distclean                  remove build and output files."
	@echo "  [docker-]buildroot-target           use Maketarget from buildroot (set as BUILDROOTTARGET variable)"
	@echo ""
	@echo "  build_img                           create a docker image as buildsystem"
	@echo ""
	@echo "Variables:"
	@echo "  BUILDROOT_VERSION                   ($(BUILDROOT_VERSION))"
	@echo "  TARGET_PLATFORM                     ($(TARGET_PLATFORM))"
	@echo "  BUILD_CONTAINER                     ($(BUILD_CONTAINER))"
	@echo "  BUILDROOTTARGET                     ($(BUILDROOTTARGET))"
	@echo "  DEFCONFIG                           ($(DEFCONFIG))"
	@echo "  VERSION                             ($(VERSION)) "
	@echo "  NAME                                ($(NAME))"
	@echo ""

###############################################################################
.PHONY: build_img
build_img: mk-tools/Dockerfile
	docker build -t $(BUILD_CONTAINER) mk-tools/

################################################################################
.PHONY: clean
clean:
	$(DOCKER_CMD) ${MAKE_CMD} clean

################################################################################
.PHONY: distclean
distclean:
	rm -rf output

################################################################################
.PHONY: download
download:
	@mkdir -p buildroot
	@mkdir -p dl
	@mkdir -p $(ROOT_DIR)/output/$(TARGET_PLATFORM)
	@mkdir -p $(ROOT_DIR)/output/$(TARGET_PLATFORM)
ifneq ("$(wildcard buildroot/Makefile)","")
	@if [ "$(BUILDROOT_VERSION)" != $$(sed -n -e '/BR2_VERSION :=/ s/.*\= //p' buildroot/Makefile) ]; then \
		echo "ERROR: Wrong buildroot version found. Need $(BUILDROOT_VERSION)."; false; \
	fi 
	@echo "Found ${BUILDROOT_FILE}"
else
	@echo "Download and unpack ${BUILDROOT_FILE}."
	@cd dl; wget -c http://buildroot.uclibc.org/downloads/${BUILDROOT_FILE}.tar.gz
	@tar -x -k -f dl/${BUILDROOT_FILE}.tar.gz -C buildroot/ --strip-components=1 || true
endif

################################################################################
.PHONY: menuconfig
menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} menuconfig;
	${MAKE_CMD} savedefconfig

################################################################################
.PHONY: busybox-menuconfig
busybox-menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} busybox-menuconfig
	${MAKE_CMD} busybox-update-config

################################################################################
.PHONY: linux-menuconfig
linux-menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} linux-menuconfig
	${MAKE_CMD} linux-update-defconfig

################################################################################
.PHONY: buildroot-target
buildroot-target: 
ifndef BUILDROOTTARGET
	$(error BUILDROOTTARGET is not set)
endif
	${MAKE_CMD} ${BUILDROOTTARGET}

################################################################################
.PHONY: build
build: download
	@echo "****************************************"
	@echo " Build Dockerclust"
	@echo "****************************************"
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD}
	sync
	@echo 
	@echo "**********"
	@echo " finished "
	@echo "**********"
