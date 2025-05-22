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
NAME ?= bzImage
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

#EXTERNAL_MASTERNODE_PATH := $(ROOT_DIR)/project/master-node
#EXTERNAL_SLAVENODE_PATH := $(ROOT_DIR)/project/slave-node
EXTERNAL_PATH := $(ROOT_DIR)/project/$(TARGET_PLATFORM)

.DEFAULT_GOAL := help
###############################################################################
# Overwrite Make command 
###############################################################################

MAKE_CMD_MASTER := make \
	 O=$(ROOT_DIR)/output/$(TARGET_PLATFORM) \
	 V=0 \
	 BR2_EXTERNAL=$(EXTERNAL_PATH) \
	 VERSION=$(VERSION) \
	 NAME=$(NAME) \
	 IMAGE_FILE=$(IMAGE_FILE) \
	 BR2_DL_DIR=$(BR2_DL_DIR) \
	 -C $(ROOT_DIR)/buildroot

#MAKE_CMD_MASTER := make \
#	 O=$(ROOT_DIR)/output/master-node \
#	 V=0 \
#	 BR2_EXTERNAL=$(EXTERNAL_MASTERNODE_PATH) \
#	 VERSION=$(VERSION) \
#	 NAME=$(NAME) \
#	 IMAGE_FILE=$(IMAGE_FILE) \
#	 BR2_DL_DIR=$(BR2_DL_DIR) \
#	 -C $(ROOT_DIR)/buildroot
#
#MAKE_CMD_SLAVE := make \
#	 O=$(ROOT_DIR)/output/slave-node \
#	 V=0 \
#	 BR2_EXTERNAL=$(EXTERNAL_SLAVENODE_PATH) \
#	 VERSION=$(VERSION) \
#	 NAME=$(NAME) \
#	 IMAGE_FILE=$(IMAGE_FILE) \
#	 BR2_DL_DIR=$(BR2_DL_DIR) \
#	 -C $(ROOT_DIR)/buildroot

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

#.PHONY: help
#help:
#	@echo "Targets:"
#	@echo "  [docker-]help                                  show this help."
#	@echo "  [docker-]build                                 builds slave and master (master depends on slave build)"
#	@echo ""
#	@echo "  [docker-][master-/slave-]menuconfig"
#	@echo "  [docker-][master-/slave-]busybox-menuconfig"
#	@echo "  [docker-][master-/slave-]linux-menuconfig"
#	@echo ""
#	@echo "  [docker-]clean-all                             remove all build files."
#	@echo "  [docker-]distclean-all                         remove all build and output files."
#	@echo "  [docker-][master-/slave-]clean                 remove all build files from slave or master."
#	@echo "  [docker-][master-/slave-]distclean             remove all build and output files from slave or master."
#	@echo "  [docker-][master-/slave-]buildroot-target      use Maketarget from buildroot (set as BUILDROOTTARGET variable)"
#	@echo ""
#	@echo "  build_img                                      create a docker image as buildsystem"
#	@echo ""
#	@echo "Variables:"
#	@echo "  BUILDROOT_VERSION                              ($(BUILDROOT_VERSION))"
#	@echo "  BUILD_CONTAINER                                ($(BUILD_CONTAINER))"
#	@echo "  BUILDROOTTARGET                                ($(BUILDROOTTARGET))"
#	@echo "  DEFCONFIG                                      ($(DEFCONFIG))"
#	@echo "  VERSION                                        ($(VERSION)) "
#	@echo "  NAME                                           ($(NAME))"
#	@echo ""

###############################################################################
.PHONY: build_img
build_img: mk-tools/Dockerfile
	docker build -t $(BUILD_CONTAINER) mk-tools/

################################################################################
.PHONY: clean
clean:
	$(DOCKER_CMD) ${MAKE_CMD} clean

#.PHONY: slave-clean
#slave-clean:
#	$(DOCKER_CMD) ${MAKE_CMD_SLAVE} clean
#
#.PHONY: master-clean
#master-clean:
#	$(DOCKER_CMD) ${MAKE_CMD_MASTER} clean
#
#.PHONY: clean-all
#clean-all: master-clean slave-clean

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

#.PHONY: download
#download:
#	@mkdir -p buildroot
#	@mkdir -p dl
#	@mkdir -p $(ROOT_DIR)/output/master-node
#	@mkdir -p $(ROOT_DIR)/output/slave-node
#ifneq ("$(wildcard buildroot/Makefile)","")
#	@if [ "$(BUILDROOT_VERSION)" != $$(sed -n -e '/BR2_VERSION :=/ s/.*\= //p' buildroot/Makefile) ]; then \
#		echo "ERROR: Wrong buildroot version found. Need $(BUILDROOT_VERSION)."; false; \
#	fi 
#	@echo "Found ${BUILDROOT_FILE}"
#else
#	@echo "Download and unpack ${BUILDROOT_FILE}."
#	@cd dl; wget -c http://buildroot.uclibc.org/downloads/${BUILDROOT_FILE}.tar.gz
#	@tar -x -k -f dl/${BUILDROOT_FILE}.tar.gz -C buildroot/ --strip-components=1 || true
#endif
################################################################################
.PHONY: menuconfig
menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} menuconfig;
	${MAKE_CMD} savedefconfig

#.PHONY: master-menuconfig
#master-menuconfig: download
#	${MAKE_CMD_MASTER} ${DEFCONFIG}
#	${MAKE_CMD_MASTER} menuconfig;
#	${MAKE_CMD_MASTER} savedefconfig
#
#.PHONY: slave-menuconfig
#slave-menuconfig: download
#	${MAKE_CMD_SLAVE} ${DEFCONFIG}
#	${MAKE_CMD_SLAVE} menuconfig;
#	${MAKE_CMD_SLAVE} savedefconfig

################################################################################
.PHONY: busybox-menuconfig
busybox-menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} busybox-menuconfig
	${MAKE_CMD} busybox-update-config

#.PHONY: master-busybox-menuconfig
#master-busybox-menuconfig: download
#	${MAKE_CMD_MASTER} ${DEFCONFIG}
#	${MAKE_CMD_MASTER} busybox-menuconfig
#	${MAKE_CMD_MASTER} busybox-update-config
#
#.PHONY: slave-busybox-menuconfig
#slave-busybox-menuconfig: download
#	${MAKE_CMD_SLAVE} ${DEFCONFIG}
#	${MAKE_CMD_SLAVE} busybox-menuconfig
#	${MAKE_CMD_SLAVE} busybox-update-config

################################################################################
.PHONY: linux-menuconfig
linux-menuconfig: download
	${MAKE_CMD} ${DEFCONFIG}
	${MAKE_CMD} linux-menuconfig
	${MAKE_CMD} linux-update-defconfig
#.PHONY: master-linux-menuconfig
#master-linux-menuconfig: download
#	${MAKE_CMD_MASTER} ${DEFCONFIG}
#	${MAKE_CMD_MASTER} linux-menuconfig
#	${MAKE_CMD_MASTER} linux-update-defconfig
#
#.PHONY: slave-linux-menuconfig
#slave-linux-menuconfig: download
#	${MAKE_CMD_SLAVE} ${DEFCONFIG}
#	${MAKE_CMD_SLAVE} linux-menuconfig
#	${MAKE_CMD_SLAVE} linux-update-defconfig

################################################################################
.PHONY: buildroot-target
buildroot-target: 
ifndef BUILDROOTTARGET
	$(error BUILDROOTTARGET is not set)
endif
	${MAKE_CMD} ${BUILDROOTTARGET}

#.PHONY: master-buildroot-target
#master-buildroot-target: 
#ifndef BUILDROOTTARGET
#	$(error BUILDROOTTARGET is not set)
#endif
#	${MAKE_CMD_MASTER} ${BUILDROOTTARGET}
#
#.PHONY: slave-buildroot-target
#slave-buildroot-target: 
#ifndef BUILDROOTTARGET
#	$(error BUILDROOTTARGET is not set)
#endif
#	${MAKE_CMD_SLAVE} ${BUILDROOTTARGET}

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

#.PHONY: build
#build: download
#	@echo "****************************************"
#	@echo " Build Slave-Node"
#	@echo "****************************************"
#	${MAKE_CMD_SLAVE} ${DEFCONFIG}
#	${MAKE_CMD_SLAVE}
#	sync
#	@echo "****************************************"
#	@echo " Prepare Master-node overlay"
#	@echo "****************************************"
#	cp ${ROOT_DIR}/output/slave-node/images/Image project/master-node/rootfs-overlay/tftpboot/
#	cp ${ROOT_DIR}/output/slave-node/images/rootfs.cpio.gz project/master-node/rootfs-overlay/tftpboot/
#	sync
#	@echo "****************************************"
#	@echo " Build Dockerclust"
#	@echo "****************************************"
#	${MAKE_CMD_MASTER} ${DEFCONFIG}
#	${MAKE_CMD_MASTER}
#	sync
#	@echo "****************************************"
#	@echo " Clean Master-Node overlay"
#	@echo "****************************************"
#	rm project/master-node/rootfs-overlay/tftpboot/Image
#	rm project/master-node/rootfs-overlay/tftpboot/rootfs.cpio.gz
#	sync
#	@echo 
#	@echo "**********"
#	@echo " finished "
#	@echo "**********"

