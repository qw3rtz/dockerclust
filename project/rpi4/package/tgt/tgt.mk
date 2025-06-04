################################################################################
#
# tgt
#
################################################################################

TGT_VERSION = 1.0.96
TGT_SITE = https://github.com/fujita/tgt/archive
TGT_SOURCE = v$(TGT_VERSION).tar.gz
TGT_DEPENDENCIES = 
TGT_LICENSE = GPL-2.0
TGT_LICENSE_FILES = COPYING

define TGT_BUILD_CMDS
    $(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC="$(TARGET_CC)" AR="$(TARGET_AR)" LD="$(TARGET_LD)"
endef

define TGT_INSTALL_TARGET_CMDS
    $(INSTALL) -D -m 0755 $(@D)/usr/tgtd $(TARGET_DIR)/usr/sbin/tgtd
    $(INSTALL) -D -m 0755 $(@D)/usr/tgtadm $(TARGET_DIR)/usr/sbin/tgtadm
endef

$(eval $(generic-package))
