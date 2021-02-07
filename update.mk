define Update/OpenWrt
	@if [ -n "$$(git -C $(1)/ branch -r | grep /$(2)$$)" ]; then\
		echo "OpenWrt version defined is a branch" ;\
		git -C $(1) stash && \
			git -C $(1) checkout $(2) && \
			git -C $(1) pull ;\
		r=$$(git -C $(1) log -1 --pretty=format:%H) ;\
		if [ -z "$$(git -C $(1)/ branch | grep wip-$(2)-$$r$$)" ]; then\
			echo "Creating new OpenWrt wip branch" ;\
			git -C $(1) checkout $(2) -b wip-$(2)-$$r ;\
		else \
			echo "OpenWrt wip branch seems to be up to date" ;\
			git -C $(1) checkout wip-$(2)-$$r ;\
		fi ;\
	else \
		echo "OpenWrt version defined is a tag/hash" ;\
		git -C $(1) stash && \
			git -C $(1) checkout master && \
			git -C $(1) pull ;\
		if [ -z "$$(git -C $(1)/ branch | grep wip-$(2)$$)" ]; then\
			echo "Creating new OpenWrt wip branch" ;\
			git -C $(1) checkout $(2) -b wip-$(2) ;\
		else \
			echo "OpenWrt wip tag/hash seems to be up to date" ;\
			git -C $(1) checkout wip-$(2) ;\
		fi ;\
	fi ;\
	touch $(1)/$(KITCHEN_PREPARED)
endef

define Update/List
	a=$$(cat $(1)/$(KITCHEN_PREPARED)) ;\
	echo -n > $(1)/$(2) ;\
	for f in $$(git diff --diff-filter=rd --name-only $$a $(KITCHEN_HASH) $(3) ); do \
		echo $${f#"$(3)/"} >> $(1)/$(2) ;\
	done ;\
	for f in $$(git diff --diff-filter=R --name-status $$a $(KITCHEN_HASH) $(3) | awk '{print $$3}'); do \
		echo $${f#"$(3)/"} >> $(1)/$(2) ;\
	done ;\
	for f in $$(git status $(3) --short | grep "?? " | awk '{print $$2;}'); do \
		echo $${f#"$(3)/"} >> $(1)/$(2) ;\
	done ;\
	for f in $$(git status $(3) --short | grep " M " | awk '{print $$2;}'); do \
		echo $${f#"$(3)/"} >> $(1)/$(2) ;\
	done ;\
	for f in $$(git status $(3) --short | grep " D " | awk '{print $$2;}'); do \
		echo "Removing $(1)/$${f#"$(3)/"} (deleted from working directory)" ;\
		rm -f $(1)/$${f#"$(3)/"} ;\
	done ;\
	for f in $$(git diff --diff-filter=R --name-status $$a $(KITCHEN_HASH) $(3) | awk '{print $$2}'); do \
		echo "Removing $(1)/$${f#"$(3)/"} (renamed by commit)" ;\
		rm -f $(1)/$${f#"$(3)/"} ;\
	done ;\
	for f in $$(git diff --diff-filter=D --name-only $$a $(KITCHEN_HASH) $(3)); do \
		echo "Removing $(1)/$${f#"$(3)/"} (deleted by commit)" ;\
		rm -f $(1)/$${f#"$(3)/"} ;\
	done
endef

define Update/Files
	if [ -d $(KITCHEN_TARGETS_DIR)/$(2)/$(3) ]; then \
		$(call Update/List,$(1),$(KITCHEN_PREPARED).$(2).$(3).list,targets/$(2)/$(3)) && \
		for f in $$(cat $(1)/$(KITCHEN_PREPARED).$(2).$(3).list 2>/dev/null); do \
			echo "Copying updated file(s) $$f to $(1)/$$f" ;\
			mkdir -p $$(dirname $(1)/$$f) ;\
			cp -r $(KITCHEN_TARGETS_DIR)/$(2)/$(3)/$$f $(1)/$$f ;\
		done ;\
		git -C $(1) add -A && \
			git -C $(1) commit -qam "$(KITCHEN_COMMIT_TAG) $(2) $(3) update to $(KITCHEN_HASH)" ;\
		mv -u $(1)/$(KITCHEN_PREPARED).$(2).$(3).list $(1)/$(KITCHEN_PREPARED).$(2).$(3) ;\
	fi
endef

define Update/IngridientsPart
	@(\
		$(call Update/Files,$(1),common,$(3)) ;\
		$(call Update/Files,$(1),$(2),$(3)) ;\
		touch $(1)/$(KITCHEN_PREPARED).$(3) ;\
	)
	@(\
		cp $(KITCHEN_TARGETS_DIR)/$(2)/$(5)/$(KITCHEN_PROFILE) $(1)/.config ;\
		version=$$(./version.sh $(2) $(KITCHEN_PROFILE)) ;\
		revision=$$(./version.sh -r $(2) $(KITCHEN_PROFILE) $(KITCHEN_TARGETS_DIR)/common/ $(KITCHEN_TARGETS_DIR)/$(2)) ;\
		echo "" >> $(1)/.config ;\
		echo "CONFIG_VERSION_NUMBER=\"$$version\"" >> $(1)/.config ;\
		echo "CONFIG_VERSION_CODE=\"$$revision\"" >> $(1)/.config ;\
		make -C $(1) defconfig ;\
		touch $(1)/$(KITCHEN_PREPARED).$(5) ;\
		echo "Target: $(2), Profile: $(KITCHEN_PROFILE), Version: $$version, Revision: $$revision" ;\
	)
	@echo $(KITCHEN_HASH) > $(1)/$(KITCHEN_PREPARED)
endef

define Update/Ingridients
	$(call Remove/Ingridients,$(1),$(6))
	$(call Prepare/Ingridients,$(1),$(2),$(3),$(4),$(5))
endef
