PREFIX ?= $(HOME)/.local
DEST   := $(PREFIX)/bin/shck

.PHONY: install uninstall regen

install: uninstall
	@mkdir -p $(dir $(DEST))
	@cp shck $(DEST)
	@chmod +x $(DEST)
	@printf "Installed to %s\n" "$(DEST)"

uninstall:
	@rm -f $(DEST)
	@printf "Removed %s\n" "$(DEST)"

devinstall: uninstall
	@mkdir -p $(dir $(DEST))
	@ln -s -f $(PWD)/shck $(DEST)
	@chmod +x $(DEST)
	@printf "Softlinked to %s\n" "$(DEST)"

regen:                m
	@sh regen.sh
	@printf "Dataset rebuilt and spliced into shck\n"
