-include env
.NOTPARALLEL:
.SECONDEXPANSION:
KITCHEN_TOPDIR:=${CURDIR}
KITCHEN_COMMIT_TAG:=kitchen:
KITCHEN_TARGETS_DIR:=$(KITCHEN_TOPDIR)/targets
KITCHEN_PREPARED:=.kprep
KITCHEN_HASH ?= abcdef12
KITCHEN_OPENWRT_GIT_DEFAULT:=git://git.openwrt.org/openwrt/openwrt.git
KITCHEN_OPENWRT_DIR = $(KITCHEN_TOPDIR)/openwrt.$(KITCHEN_TARGET).$(KITCHEN_PROFILE)
KITCHEN_OPENWRT_DL ?= $(KITCHEN_OPENWRT_DIR)/dl
KITCHEN_OPENWRT_BD ?= $(KITCHEN_OPENWRT_DIR)/build_dir
KITCHEN_OPENWRT_SD ?= $(KITCHEN_OPENWRT_DIR)/staging_dir
KITCHEN_TARGETS:=$(shell ls $(KITCHEN_TARGETS_DIR) | grep -v common)

KITCHEN_OPENWRT_SRC_FILE=$(KITCHEN_TARGETS_DIR)/$(KITCHEN_TARGET)/src
KITCHEN_OPENWRT_VERSION_FILE=$(KITCHEN_TARGETS_DIR)/$(KITCHEN_TARGET)/version

default: none
none:
	@echo "Please define target/profile/action"
	@echo "Available targets: $(KITCHEN_TARGETS)"
	@echo "Available target/profile combinations:"
	@for i in $(KITCHEN_TARGETS); do for c in $$(ls targets/$$i/configs/); do echo "    $$i/$$c"; done done

vars/%:
	$(eval KITCHEN_TARGET:=$(patsubst %/,%,$(dir $*)))
	$(eval KITCHEN_PROFILE:=$(notdir $*))
	$(eval KITCHEN_OPENWRT_GIT?=$(shell cat $(KITCHEN_OPENWRT_SRC_FILE) 2>/dev/null))
	$(eval KITCHEN_OPENWRT_VERSION:=$(shell cat $(KITCHEN_OPENWRT_VERSION_FILE)))
	$(eval KITCHEN_OPENWRT_DIR:=$(KITCHEN_TOPDIR)/openwrt.$(KITCHEN_TARGET).$(KITCHEN_PROFILE))
	$(eval KITCHEN_OPENWRT_BD:=$(shell echo $(KITCHEN_OPENWRT_BD) | sed "s,%t,$(KITCHEN_TARGET),g" | sed "s,%p,$(KITCHEN_PROFILE),g"))
	$(eval KITCHEN_OPENWRT_SD:=$(shell echo $(KITCHEN_OPENWRT_SD) | sed "s,%t,$(KITCHEN_TARGET),g" | sed "s,%p,$(KITCHEN_PROFILE),g"))
	$(eval KITCHEN_HASH:=$(shell git log -1 --pretty=format:"%H" 2>/dev/null))

define Realpath
	$(shell realpath -m $(1))
endef

include remove.mk
include prepare.mk
include update.mk

prepare/%:
	@echo target is $(KITCHEN_TARGET)
	@echo profile is $(KITCHEN_PROFILE)
	@echo preparing OpenWrt directory $(KITCHEN_OPENWRT_DIR) ...
	$(call Prepare/OpenWrt,\
		$(KITCHEN_OPENWRT_DIR),\
		$(if $(KITCHEN_OPENWRT_GIT),$(KITCHEN_OPENWRT_GIT),$(KITCHEN_OPENWRT_GIT_DEFAULT)),\
		$(KITCHEN_OPENWRT_VERSION))
	$(call Prepare/Env,\
		$(call Realpath,$(KITCHEN_OPENWRT_DIR)),\
		$(call Realpath,$(KITCHEN_OPENWRT_DL)),\
		$(call Realpath,$(KITCHEN_OPENWRT_BD)),\
		$(call Realpath,$(KITCHEN_OPENWRT_SD)))
	$(call Prepare/Ingridients,$(KITCHEN_OPENWRT_DIR),$(KITCHEN_TARGET),files,patches,configs)
	@echo dl cache is in $(KITCHEN_OPENWRT_DL)
	@echo build_dir is $(KITCHEN_OPENWRT_BD)
	@echo staging_dir is $(KITCHEN_OPENWRT_SD)

$(KITCHEN_TARGETS:=/%/prepare): vars/$$(@D) prepare/$$(dir $$(@D))
	@echo $(@F) stage done

$(KITCHEN_TARGETS:=/%/compile): $$(@D)/prepare
	$(MAKE) -C $(KITCHEN_OPENWRT_DIR)
	@echo $(@F) stage done

$(KITCHEN_TARGETS:=/%/clean): $$(@D)/prepare
	$(MAKE) -C $(KITCHEN_OPENWRT_DIR) $(@F)
	@echo $(@F) stage done

$(KITCHEN_TARGETS:=/%/dirclean): $$(@D)/prepare
	$(MAKE) -C $(KITCHEN_OPENWRT_DIR) $(@F)
	@echo $(@F) stage done

$(KITCHEN_TARGETS:=/%/distclean): $$(@D)/prepare
	$(MAKE) -C $(KITCHEN_OPENWRT_DIR) $(@F)
	@echo $(@F) stage done

dirclean:
	@for d in $(KITCHEN_TARGETS); do rm -rf $(KITCHEN_OPENWRT_DIR)$$d; done
	@rm -rf $(KITCHEN_OPENWRT_DIR)*

update/%:
	$(call Update/OpenWrt,$(KITCHEN_OPENWRT_DIR),$(KITCHEN_OPENWRT_VERSION))
	$(call Prepare/Env,\
		$(call Realpath,$(KITCHEN_OPENWRT_DIR)),\
		$(call Realpath,$(KITCHEN_OPENWRT_DL)),\
		$(call Realpath,$(KITCHEN_OPENWRT_BD)),\
		$(call Realpath,$(KITCHEN_OPENWRT_SD)))
	@echo Now on $(KITCHEN_OPENWRT_VERSION)
	$(call Update/Ingridients,$(KITCHEN_OPENWRT_DIR),$(KITCHEN_TARGET),files,patches,configs,$(KITCHEN_OPENWRT_VERSION))
	@echo Ingridients refreshed

$(KITCHEN_TARGETS:=/%/update): $$(@D)/prepare update/$$(dir $$(@D))
	@echo $(@F) stage done

update-part/%:
	$(call Update/IngridientsPart,$(KITCHEN_OPENWRT_DIR),$(KITCHEN_TARGET),files,patches,configs,$(KITCHEN_OPENWRT_VERSION))
	@echo Ingridients partially refreshed

$(KITCHEN_TARGETS:=/%/update-part): $$(@D)/prepare update-part/$$(dir $$(@D))
	@echo $(@F) stage done
