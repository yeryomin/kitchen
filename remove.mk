# Revert patches
# $(1) -- OpenWrt directory name
# $(2) -- target name
# $(3) -- patches directory name
define Remove/Patches
	echo "running Remove/Patches ..." ;\
	cat $(1)/$(KITCHEN_PREPARED).$(2).$(3) ;\
	if [ -f $(1)/$(KITCHEN_PREPARED).$(2).$(3) ]; then \
		for p in $$(cat $(1)/$(KITCHEN_PREPARED).$(2).$(3)); do \
			echo "Reverting $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/$$p" ;\
			patch --no-backup-if-mismatch -R -sN -p1 -d $(1)/ < $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/$$p ;\
		done ;\
		echo "removing $(1)/$(KITCHEN_PREPARED).$(2).$(3)" ;\
		rm -f $(1)/$(KITCHEN_PREPARED).$(2).$(3) ;\
	fi
endef

define Remove/Ingridients
	if [ -d $(1) ]; then \
		$(call Remove/Patches,$(1),$(2),patches-feeds) ;\
		git -C $(1) reset --hard $(3) ;\
		echo "$(KITCHEN_PREPARED)*" >> $(1)/.gitignore ;\
		rm -rf $(1)/tmp/ ;\
		rm -f $(1)/.config* ;\
		rm -f $(1)/$(KITCHEN_PREPARED).* ;\
	fi
endef
