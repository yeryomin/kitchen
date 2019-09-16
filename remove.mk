define Remove/Ingridients
	if [ -d $(1) ]; then \
		git -C $(1) reset --hard $(2) ;\
		echo "$(KITCHEN_PREPARED)*" >> $(1)/.gitignore ;\
		rm -rf $(1)/tmp/ ;\
		rm -f $(1)/.config* ;\
		rm -f $(1)/$(KITCHEN_PREPARED).* ;\
	fi
endef
