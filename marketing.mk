help-marketing: ## Display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@awk -F ':.*?## ' '/^[a-zA-Z]/ && NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | grep marketing | sort

marketing-shell: dev.shell.marketing ## Run a shell on the marketing site container

stop-marketing: dev.stop ## Stop all services (including the marketing site) with host volumes

down-marketing: dev.down  ## Bring down all services (including the marketing site) with host volumes

up-marketing: ## Bring up all services (including the marketing site) with host volumes
	docker-compose up

up-marketing-detached: dev.up dev.up.marketing  ## Bring up all services (including the marketing site) with host volumes (in detached mode)

up-marketing-sync:  ## Bring up all services (including the marketing site) with docker-sync
	docker-sync-stack start -c docker-sync-marketing-site.yml

clean-marketing-sync:   ## Remove the docker-sync containers for all services (including the marketing site)
	docker-sync-stack clean -c docker-sync-marketing-site.yml
