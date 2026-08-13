PREFIX ?= $(HOME)/.local
DEST   := $(PREFIX)/bin/shck

.PHONY: install uninstall

install: uninstall
	@mkdir -p $(dir $(DEST))
	@cp shck $(DEST)
	@chmod +x $(DEST)
	@printf "Installed to %s\n" "$(DEST)"

uninstall:
	@rm -f $(DEST)
	@printf "Removed %s\n" "$(DEST)"
