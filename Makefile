# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

SHELL := /usr/bin/env bash

# COLORS
RED=$(shell echo -e "\033[0;31m")
GRE=$(shell echo -e "\033[0;32m")
NC=$(shell echo -e "\033[0m")

# TERRAFORM INSTALL
version  ?= "1.0.10"
os       ?= $(shell uname|tr A-Z a-z)
ifeq ($(shell uname -m),x86_64)
  arch   ?= "amd64"
endif
ifeq ($(shell uname -m),i686)
  arch   ?= "386"
endif
ifeq ($(shell uname -m),aarch64)
  arch   ?= "arm"
endif

# CHECK TERRAFORM VERSION
TERRAFORM := $(shell command -v terraform 2> /dev/null)
USER_HOME_DIRECTORY := $(HOME)
TERRAFORM_VERSION := $(shell terraform --version 2> /dev/null)
REGION := $(shell aws configure get region)

all: local plan apply git-private configure-auth upload configure-external-dns configure-keycloak destroy clean
	@echo "$(GRE) INFO: Applying all options"

.PHONY: apply clean destroy configure-auth plan upload
local:
	@terraform --version
ifdef TERRAFORM
	@echo "$(GRE) INFO: The local Terraform version is $(TERRAFORM_VERSION)"
else
	@echo "$(RED) ERROR: Terraform is not installed"
endif

clean:
	@echo "$(RED) INFO: Removing local Terraform generated files"
	@rm -rf .terraform* terraform.tfs*

plan:
	@echo "$(GRE) INFO: Initialize the working directory and planning"
	cd terraform/ \
	@terraform init -reconfigure && \
	terraform fmt && \
	terraform validate && \
	terraform plan

apply:
	@echo "$(GRE) INFO: Applying planned resources"
	cd terraform/ \
	@terraform init -reconfigure && \
	terraform validate && \
	terraform apply --auto-approve -var-file=terraform.tfvars

update-kube-config:
	@echo "$(GRE) INFO: Configuring Kube config."
	set -ex
	aws eks update-kubeconfig --name keycloak-demo --region $(REGION)

deploy-keycloak:
	@echo "$(GRE) INFO: Deploying Keycloak to EKS."
	set -ex
	cd terraform/ && \
	kubectl apply -f  manifest/keycloak.yml

destroy:
	@echo "$(RED) INFO: Removing all Terraform created resources"
	set -ex
	cd terraform/ && \
	kubectl delete -f manifest/keycloak.yml && \
	terraform init -reconfigure && \
	terraform validate && \
	terraform destroy --auto-approve -var-file=terraform.tfvars

