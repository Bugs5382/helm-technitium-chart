# MIT License
#
# Copyright (c) 2026 Shane
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
SHELL := bash

ifndef NO_COLOR
YELLOW=\033[0;33m
CYAN=\033[1;36m
RED=\033[31m
# no color
NC=\033[0m
endif

WORKING_DIR := $(shell pwd)
GOLIC_VERSION  ?= v0.1.0
GOBIN=$(shell go env GOPATH)/bin

.PHONY: lint-init
lint-init:
	@echo -e "\n$(CYAN)Check for lint dependencies$(NC)"
	brew install golangci-lint
	brew install gitleaks
	brew install yamllint

# Paths
GOBIN=$(shell go env GOPATH)/bin
PATH:=$(GOBIN):$(PATH)

# Colors for output
YELLOW := \033[1;33m
CYAN   := \033[1;36m
RED    := \033[0;31m
NC     := \033[0m

define golic
	@go install github.com/Bugs5382/golic@$(GOLIC_VERSION)
	$(GOBIN)/golic inject $1
endef

.PHONY: license
license:
	@echo -e "\n$(YELLOW)Injecting the license$(NC)"
	@if [ ! -f $(GOBIN)/golic ]; then \
		echo "Installing golic..."; \
		go install github.com/Bugs5382/golic@$(GOLIC_VERSION); \
	fi
	golic inject -p '.golic.yaml' -t mit -c "2026 Shane"

.PHONY: lint
lint:
	@echo -e "\n$(YELLOW)Running the linters$(NC)"

	@echo -e "\n$(CYAN)Checking/Installing Dependencies$(NC)"
	@# Gitleaks requires the 'zricethezav' path due to module declaration rules
	@if [ ! -f $(GOBIN)/gitleaks ]; then \
		echo "Installing gitleaks..."; \
		go install github.com/zricethezav/gitleaks/v8@latest; \
	fi

	@echo -e "\n$(CYAN)yamllint$(NC)"
	@if which yamllint > /dev/null; then \
		yamllint .; \
	else \
		echo -e "$(RED)yamllint not found. Install via 'brew install yamllint'$(NC)"; \
	fi

	@echo -e "\n$(CYAN)gitleaks$(NC)"
	@$(GOBIN)/gitleaks detect . --no-git --verbose --config=.gitleaks.toml

	@echo -e "\n$(CYAN)helm lint$(NC)"
	@helm lint technitium