define Prepare/OpenWrt
	@echo preparing OpenWrt source version $(3) from $(2) ...
	@[ -f $(1)/$(KITCHEN_PREPARED) ] || (\
		rm -rf $(1) && \
		git clone $(2) $(1) && (\
			git -C $(1) checkout $(3) ;\
			r=$$(git -C $(1) log -1 --pretty=format:%H) ;\
			if [ "$$r" = "$(strip $(3))" ]; then \
				git -C $(1) checkout $(3) -b wip-$(strip $(3)) ;\
			else \
				git -C $(1) checkout $(3) -b wip-$(strip $(3))-$$r ;\
			fi ;\
			echo "$(KITCHEN_PREPARED)*" >> $(1)/.gitignore ;\
			touch $(1)/$(KITCHEN_PREPARED) ;\
		)\
	)
endef

define Prepare/Dir
	@[ -f $(1)/$(2)/$(KITCHEN_PREPARED) ] || (\
		mkdir -p $(3) ;\
		if [ "$(1)/$(2)" != "$(3)" ]; then \
			ln -sf $(3) $(1)/$(2) ;\
		fi ;\
		touch $(3)/$(KITCHEN_PREPARED) ;\
	)
endef

define Prepare/Env
	$(call Prepare/Dir,$(strip $(1)),dl,$(strip $(2)))
	$(call Prepare/Dir,$(strip $(1)),build_dir,$(strip $(3)))
	$(call Prepare/Dir,$(strip $(1)),staging_dir,$(strip $(4)))
endef

define Prepare/List
	find $(2) -type f -printf "%P\n" | sort > $(1)
endef

define Prepare/Files
	if [ -d $(KITCHEN_TARGETS_DIR)/$(2)/$(3) ]; then \
		$(call Prepare/List,$(1)/$(KITCHEN_PREPARED).$(2).$(3).list,$(KITCHEN_TARGETS_DIR)/$(2)/$(3)) && \
		cp -r $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/* $(1)/ && \
		git -C $(1) add -A && \
			git -C $(1) commit -qam "$(KITCHEN_COMMIT_TAG) $(2) $(3)" ;\
		mv -u $(1)/$(KITCHEN_PREPARED).$(2).$(3).list $(1)/$(KITCHEN_PREPARED).$(2).$(3) ;\
	fi
endef

# patch OpenWrt directory
# $(1) -- OpenWrt directory name
# $(2) -- target name
# $(3) -- patches directory name
define Prepare/Patches
	if [ -d $(KITCHEN_TARGETS_DIR)/$(2)/$(3) ]; then \
		$(call Prepare/List,$(1)/$(KITCHEN_PREPARED).$(2).$(3).list,$(KITCHEN_TARGETS_DIR)/$(2)/$(3)) && \
		for p in $$(cat $(1)/$(KITCHEN_PREPARED).$(2).$(3).list); do \
			echo "Applying $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/$$p" ;\
			patch -sN -p1 -d $(1)/ < $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/$$p ;\
			if [ $$? = 0 ]; then \
				git -C $(1) add -A ;\
				git -C $(1) commit -qam "$(KITCHEN_COMMIT_TAG) $(2) $(3) $$p" ;\
			else \
				echo "Patching failed, resetting state to '$(KITCHEN_OPENWRT_VERSION)'..." ;\
				$(call Remove/Ingridients,$(1),$(KITCHEN_OPENWRT_VERSION)) ;\
				exit 1 ;\
			fi \
		done ;\
		echo "creating $(1)/$(KITCHEN_PREPARED).$(2).$(3)" ;\
		mv -u $(1)/$(KITCHEN_PREPARED).$(2).$(3).list $(1)/$(KITCHEN_PREPARED).$(2).$(3) ;\
	fi
endef

# copy files, patch OpenWrt directory, generate .config
# $(1) -- OpenWrt directory name
# $(2) -- target name
# $(3) -- files directory name
# $(4) -- patches directory name
# $(5) -- configs directory name
define Prepare/Ingridients
	@[ -f $(1)/$(KITCHEN_PREPARED).$(3) ] || (\
		$(call Prepare/Files,$(1),common,$(3)) ;\
		$(call Prepare/Files,$(1),$(2),$(3)) ;\
		touch $(1)/$(KITCHEN_PREPARED).$(3) ;\
	)
	@[ -f $(1)/$(KITCHEN_PREPARED).$(4) ] || (\
		$(call Prepare/Patches,$(1),common,$(4)) ;\
		$(call Prepare/Patches,$(1),$(2),$(4)) ;\
		echo "creating $(1)/$(KITCHEN_PREPARED).$(4)" ;\
		touch $(1)/$(KITCHEN_PREPARED).$(4) ;\
	)
	@[ -f $(1)/$(KITCHEN_PREPARED).$(5) ] || (\
		cp $(KITCHEN_TARGETS_DIR)/$(2)/$(5)/$(KITCHEN_PROFILE) $(1)/.config ;\
		version=$$(git describe --abbrev=0) ;\
		revision=$$(./version.sh $(KITCHEN_TARGETS_DIR)/common/ $(KITCHEN_TARGETS_DIR)/$(2)) ;\
		echo "CONFIG_VERSION_NUMBER=\"$$version\"" >> $(1)/.config ;\
		echo "CONFIG_VERSION_CODE=\"$$revision\"" >> $(1)/.config ;\
		make -C $(1) defconfig ;\
		touch $(1)/$(KITCHEN_PREPARED).$(5) ;\
		echo "Target: $(2), Profile: $(KITCHEN_PROFILE), Version: $$version, Revision: $$revision" ;\
	)
endef
