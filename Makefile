SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

JQ           := jq
BATS         := bats
SHELLCHECK   := shellcheck
BUN          := bun
HOOKS_SCRIPTS := hooks/scripts
TEST_DIR      := test

#------------------------------------------------------------------------------
# Phony Targets Declaration
#------------------------------------------------------------------------------

.PHONY: help sync fmt lint typecheck check qa clean distclean
.PHONY: test hooks.test opencode.test

#------------------------------------------------------------------------------
# High-Level Targets
#------------------------------------------------------------------------------

check: fmt lint typecheck
qa: check test
test: hooks.test opencode.test

#------------------------------------------------------------------------------
# Setup
#------------------------------------------------------------------------------

sync:
	which $(BATS) >/dev/null 2>&1 || brew install bats-core
	which $(SHELLCHECK) >/dev/null 2>&1 || brew install shellcheck
	which $(JQ) >/dev/null 2>&1 || brew install jq
	which $(BUN) >/dev/null 2>&1 || brew install bun

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------

fmt:
	which shfmt >/dev/null 2>&1 && shfmt -w -i 2 $(HOOKS_SCRIPTS)/ || true

lint:
	$(SHELLCHECK) $(HOOKS_SCRIPTS)/*.sh

typecheck:
	true

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

hooks.test:
	$(BATS) $(TEST_DIR)/hooks.bats $(TEST_DIR)/hooks_e2e.bats

opencode.test:
	$(BUN) test $(TEST_DIR)/opencode.test.ts
	$(BATS) $(TEST_DIR)/opencode_e2e.bats

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

clean:
	rm -rf hooks/logs/ .opencode/logs/

distclean: clean

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	printf "\033[36m"
	printf "██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗\n"
	printf "██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝\n"
	printf "███████║██║   ██║██║   ██║█████╔╝ ███████╗\n"
	printf "██╔══██║██║   ██║██║   ██║██╔═██╗ ╚════██║\n"
	printf "██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████║\n"
	printf "╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝\n"
	printf "\033[0m\n"
	printf "Usage: make [target]\n\n"
	printf "\033[1;35mSetup:\033[0m\n"
	printf "  sync         Install required tools (bats, shellcheck, jq)\n"
	printf "\n"
	printf "\033[1;35mDev:\033[0m\n"
	printf "  fmt          Format scripts with shfmt\n"
	printf "  lint         Lint scripts with shellcheck\n"
	printf "  check        fmt + lint + typecheck\n"
	printf "  qa           check + test (quality gate)\n"
	printf "\n"
	printf "\033[1;35mTest:\033[0m\n"
	printf "  test         Run all tests\n"
	printf "  hooks.test   Run copilot hook bats tests\n"
	printf "  opencode.test Run opencode plugin tests (bun unit + bats e2e)\n"
	printf "\n"
	printf "\033[1;35mClean:\033[0m\n"
	printf "  clean        Remove log artifacts\n"
