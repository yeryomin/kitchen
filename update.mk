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

define Update/Ingridients
	$(call Remove/Ingridients,$(1),$(6))
	$(call Prepare/Ingridients,$(1),$(2),$(3),$(4),$(5))
endef
