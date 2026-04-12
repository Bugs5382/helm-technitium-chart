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

.PHONY: license
license:
	@echo -e "\n$(YELLOW)Injecting the license$(NC)"
	@if [ ! -f $(GOBIN)/golic ]; then \
		echo "Installing golic..."; \
		go install github.com/Bugs5382/golic@$(GOLIC_VERSION); \
	fi
	@$(GOBIN)/golic inject -t mit -c "2026 Shane"

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