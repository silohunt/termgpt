# Makefile for TermGPT
# POSIX-compliant installation

# Installation directories (follows FHS)
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/termgpt
POSTPROCDIR = $(LIBDIR)/post-processing
SHAREDIR = $(PREFIX)/share/termgpt
DOCDIR = $(PREFIX)/share/doc/termgpt
MANDIR = $(PREFIX)/share/man/man1

# User configuration directory
USER_CONFIG = $(HOME)/.config/termgpt

# Default target
all:
	@echo "TermGPT - Natural language to shell commands"
	@echo ""
	@echo "Available targets:"
	@echo "  install       Install to system directories (may require sudo)"
	@echo "  install-user  Install for current user only"
	@echo "  uninstall     Comprehensive removal of all TermGPT files"
	@echo "  test          Run test suite"
	@echo "  test-eval     Run evaluation tests (requires installation)"
	@echo "  clean         Clean temporary files"
	@echo ""
	@echo "For uninstallation, run: make uninstall"

# System-wide installation
install:
	@echo "Installing TermGPT to $(PREFIX)..."
	install -d $(BINDIR)
	install -d $(LIBDIR)
	install -d $(POSTPROCDIR)
	install -d $(POSTPROCDIR)/lib
	install -d $(POSTPROCDIR)/corrections
	install -d $(SHAREDIR)
	install -d $(DOCDIR)
	install -d $(MANDIR)
	install -m 755 bin/termgpt $(BINDIR)/
	install -m 755 bin/termgpt-init $(BINDIR)/
	install -m 755 bin/termgpt-shell $(BINDIR)/
	install -m 755 bin/termgpt-history $(BINDIR)/
	install -m 644 lib/termgpt-check.sh $(LIBDIR)/
	install -m 644 lib/termgpt-platform.sh $(LIBDIR)/
	install -m 644 lib/termgpt-history.sh $(LIBDIR)/
	install -m 755 lib/token-counter.py $(LIBDIR)/
	install -m 644 post-processing/lib/postprocess.sh $(POSTPROCDIR)/lib/
	install -m 644 post-processing/corrections/*.sh $(POSTPROCDIR)/corrections/
	install -m 644 share/termgpt/rules.txt $(SHAREDIR)/
	install -m 644 doc/README.md $(DOCDIR)/
	@if [ -f man/man1/termgpt.1 ]; then \
		install -m 644 man/man1/termgpt.1 $(MANDIR)/; \
	fi
	@echo "Installation complete!"
	@echo "Run 'termgpt' to use the tool"

# User-only installation
install-user:
	@echo "Installing TermGPT for current user..."
	install -d $(USER_CONFIG)
	install -d $(USER_CONFIG)/lib
	install -d $(USER_CONFIG)/post-processing
	install -d $(USER_CONFIG)/post-processing/lib
	install -d $(USER_CONFIG)/post-processing/corrections
	install -m 644 lib/termgpt-check.sh $(USER_CONFIG)/lib/
	install -m 644 post-processing/lib/postprocess.sh $(USER_CONFIG)/post-processing/lib/
	install -m 644 post-processing/corrections/*.sh $(USER_CONFIG)/post-processing/corrections/
	install -m 644 share/termgpt/rules.txt $(USER_CONFIG)/
	@echo "User installation complete!"
	@echo "Add $(PWD)/bin to your PATH:"
	@echo "  export PATH=\"\$$PATH:$(PWD)/bin\""

# Uninstall
uninstall:
	@echo "Removing TermGPT from $(PREFIX)..."
	rm -f $(BINDIR)/termgpt
	rm -f $(BINDIR)/termgpt-init
	rm -f $(BINDIR)/termgpt-history
	rm -rf $(LIBDIR)
	rm -rf $(SHAREDIR)
	rm -rf $(DOCDIR)
	rm -f $(MANDIR)/termgpt.1
	@echo "TermGPT uninstalled successfully!"
	@echo "Note: User config (~/.config/termgpt) was not removed"

# Run tests
test:
	@echo "Running test suite..."
	cd tests && sh termgpt-test.sh

# Run evaluation tests
test-eval:
	@echo "Running evaluation suite..."
	@echo "Note: This requires TermGPT to be installed or in PATH"
	cd tests/evaluation && ./run_focused_evaluation.sh

# Clean
clean:
	@echo "Cleaning temporary files..."
	find . -name "*.tmp" -delete
	find . -name "*~" -delete

.PHONY: all install install-user uninstall test test-eval clean