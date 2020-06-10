########################################################################################################################
#
# When adding a new target:
#   - If you are adding a new service make sure the dev.reset target will fully reset said service.
#
########################################################################################################################
.DEFAULT_GOAL := help

.PHONY: analytics-pipeline-devstack-test check-memory dev.backup \
        dev.build-courses dev.cache-programs dev.check dev.checkout dev.clone \
        dev.clone.ssh dev.create-test-course dev.destroy dev.down \
        dev.feature-toggle-state dev.kill dev.logs dev.nfs.setup \
        devpi-password dev.provision dev.provision.services \
        dev.provision.xqueue dev.ps dev.pull dev.repo.reset dev.reset \
        dev.restart dev.restore dev.rm-stopped dev.shell.analyticspipeline \
        dev.shell.credentials dev.shell.discovery dev.shell.e2e \
        dev.shell.ecommerce dev.shell.lms dev.shell.lms-watcher \
        dev.shell.registrar dev.shell.studio dev.shell.studio-watcher \
        dev.shell.xqueue dev.shell.xqueue_consumer dev.stats dev.status \
        dev.stop dev.sync.daemon.start dev.sync.provision \
        dev.sync.requirements dev.sync.up dev.up dev.up.watchers \
        dev.up.with-programs dev.up.with-watchers dev.validate e2e-tests \
        forum-restart-devserver help lms-restart lms-static lms-update-db \
        requirements selfcheck static studio-restart studio-static \
        studio-update-db update-db upgrade upgrade validate-lms-volume \
        vnc-passwords xqueue_consumer-restart xqueue-restart

# Colors for Make messages.
RED="\033[0;31m"
YELLOW="\033[0;33m"
GREY="\033[1;90m"
NO_COLOR="\033[0m"

# Include options (configurable through options.local.mk)
include options.mk

# List of Makefile targets to run database migrations, in the form $(service)-update-db
# Services will only have their migrations added here
# if the service is present in both $(DEFAULT_SERVICES) and $(DB_SERVICES).
DB_MIGRATION_TARGETS = \
$(foreach db_service,$(DB_SERVICES),\
	$(if $(filter $(db_service), $(DEFAULT_SERVICES)),\
		$(db_service)-update-db))

# This is equal to DEFAULT_SERVICES, but separated with plus signs,
# as commands like `make dev.up.%` and `make dev.pull.%` expect.
DEFAULT_SERVICE_LIST = $(subst  ,+,$(DEFAULT_SERVICES))

# Docker Compose YAML files to define services and their volumes.
# This environment variable tells `docker-compose` which files to load definitions
# of services, volumes, and networks from.
# Depending on the value of FS_SYNC_STRATEGY, we use a slightly different set of
# files, enabling use of different strategies to synchronize files between the host and
# the containers.
# Some services are only available for certain values of FS_SYNC_STRATEGY.
# For example, the LMS/Studio asset watchers are only available for local-mounts and nfs,
# and XQueue and the Analytics Pipeline are only available for local-mounts.

# Compose files are separated by a colon.
COMPOSE_PATH_SEPARATOR := :

ifeq ($(FS_SYNC_STRATEGY),local-mounts)
COMPOSE_FILE := docker-compose-host.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-themes.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-watchers.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-xqueue.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-analytics-pipeline.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-marketing-site.yml
endif

ifeq ($(FS_SYNC_STRATEGY),nfs)
COMPOSE_FILE := docker-compose-host-nfs.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-themes-nfs.yml
COMPOSE_FILE := $(COMPOSE_FILE):docker-compose-watchers-nfs.yml
endif

ifeq ($(FS_SYNC_STRATEGY),docker-sync)
COMPOSE_FILE := docker-compose-sync.yml
COMPOSE_FILE := docker-sync-marketing-site.yml
endif

ifndef COMPOSE_FILE
$(error FS_SYNC_STRATEGY is set to $(FS_SYNC_STRATEGY). Must be one of: local-mounts, nfs, docker-sync)
endif

# All three filesystem synchronization strategy require the main docker-compose.yml file.
COMPOSE_FILE := docker-compose.yml:$(COMPOSE_FILE)

OS := $(shell uname)

# Need to run some things under winpty in a Windows git-bash shell
# (but not when calling bash from a command shell or PowerShell)
ifneq (,$(MINGW_PREFIX))
    WINPTY := winpty
else
    WINPTY :=
endif

# Don't try redirecting to /dev/null in any Windows shell
ifneq (,$(findstring MINGW,$(OS)))
    DEVNULL :=
else
    DEVNULL := >/dev/null
endif

# Export Makefile variables to recipe shells.
export

# Include redundant targets as aliases to commands in this Makefile.
# These are split out into order to make this Makefile more approachable
# and consistent while still preserving backwards compatibility.
include aliases.mk

# Include local makefile with additional targets.
-include local.mk  # Prefix with hyphen to tolerate absence of file.

# Generates a help message. Borrowed from https://github.com/pydanny/cookiecutter-djangopackage.
help: ## Display this help message
	@echo "Please use \`make <target>' where <target> is one of"
	@awk -F ':.*?## ' '/^[a-zA-Z]/ && NF==2 {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

requirements: ## Install requirements
	pip install -r requirements/base.txt

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: ## Upgrade requirements with pip-tools
	pip install -qr requirements/pip-tools.txt
	pip-compile --upgrade -o requirements/pip-tools.txt requirements/pip-tools.in
	pip-compile --upgrade -o requirements/base.txt requirements/base.in

dev.print-container.%: ## Get the ID of the running container for a given service. Run with ``make --silent`` for just ID.
	@echo $$(docker-compose ps --quiet $*)

dev.ps: ## View list of created services and their statuses.
	docker-compose ps

dev.checkout: ## Check out "openedx-release/$OPENEDX_RELEASE" in each repo if set, "master" otherwise
	./repo.sh checkout

dev.clone: ## Clone service repos using HTTPS method to the parent directory
	./repo.sh clone

dev.clone.ssh: ## Clone service repos using SSH method to the parent directory
	./repo.sh clone_ssh

dev.provision.services: ## Provision default services with local mounted directories
	# We provision all default services as well as 'e2e' (end-to-end tests).
	# e2e is not part of `DEFAULT_SERVICE_LIST` because it isn't a service;
	# it's just a way to tell ./provision.sh that the fake data for end-to-end
	# tests should be prepared.
	$(WINPTY) bash ./provision.sh $(DEFAULT_SERVICE_LIST)+e2e

dev.provision.services.%: ## Provision specified services with local mounted directories, separated by plus signs
	$(WINPTY) bash ./provision.sh $*

dev.provision: check-memory dev.clone.ssh dev.provision.services stop ## Provision dev environment with default services, and then stop them.

dev.cache-programs: ## Copy programs from Discovery to Memcached for use in LMS.
	$(WINPTY) bash ./programs/provision.sh cache

dev.provision.xqueue: dev.provision.services.xqueue

dev.reset: down dev.repo.reset pull dev.up static update-db ## Attempts to reset the local devstack to the master working state

dev.status: ## Prints the status of all git repositories
	$(WINPTY) bash ./repo.sh status

dev.repo.reset: ## Attempts to reset the local repo checkouts to the master working state
	$(WINPTY) bash ./repo.sh reset

dev.pull: dev.pull.$(DEFAULT_SERVICE_LIST) ## Pull Docker images required by default services.

dev.pull.without-deps.%: ## Pull latest Docker images for services (separated by plus-signs).
	docker-compose pull $$(echo $* | tr + " ")

dev.pull.%: ## Pull latest Docker images for services (separated by plus-signs) and all their dependencies.
	docker-compose pull --include-deps $$(echo $* | tr + " ")

dev.up: dev.up.$(DEFAULT_SERVICE_LIST) check-memory ## Bring up default services.

dev.up.%: check-memory ## Bring up specific services (separated by plus-signs) and their dependencies with host volumes.
	docker-compose up -d $$(echo $* | tr + " ")
ifeq ($(ALWAYS_CACHE_PROGRAMS),true)
	make dev.cache-programs
endif

dev.up.without-deps.%: check-memory ## Bring up specific services (separated by plus-signs) without dependencies.
	docker-compose up --d --no-deps $$(echo $* | tr + " ")

dev.up.with-programs: dev.up dev.cache-programs ## Bring up a all services and cache programs in LMS.

dev.up.with-programs.%: dev.up.$* dev.cache-programs ## Bring up a service and its dependencies and cache programs in LMS.

dev.up.with-watchers: dev.up dev.up.watchers ## Bring up default services with LMS and Studio asset watcher containers.

dev.up.watchers: dev.up.lms_watcher+studio_watcher ## Bring up LMS and Studio asset watcher containers.

dev.nfs.setup:  ## Sets up an nfs server on the /Users folder, allowing nfs mounting on docker
	./setup_native_nfs_docker_osx.sh

dev.nfs.%:
	FS_SYNC_STRATEGY=nfs make dev.$*

# TODO: Improve or rip out Docker Sync targets.
#       They are not well-fleshed-out and it is not clear if anyone uses them.

dev.sync.daemon.start: ## Start the docker-sycn daemon
	docker-sync start

dev.sync.provision: dev.sync.daemon.start ## Provision with docker-sync enabled
	FS_SYNC_STRATEGY=docker-sync make dev.provision

dev.sync.requirements: ## Install requirements
	gem install docker-sync

dev.sync.up: dev.sync.daemon.start ## Bring up all services with docker-sync enabled
	FS_SYNC_STRATEGY=docker-sync make dev.up

dev.check: dev.check.$(DEFAULT_SERVICE_LIST) ## Run checks for the default service set.

dev.check.%:  # Run checks for a given service or set of services (separated by plus-signs).
	$(WINPTY) bash ./check.sh $*

dev.stop: ## Stop all services.
	(test -d .docker-sync && docker-sync stop) || true ## Ignore failure here
	docker-compose stop

dev.stop.%: ## Stop specific services, separated by plus-signs.
	docker-compose stop $$(echo $* | tr + " ")

dev.restart: ## Restart all services.
	docker-compose restart $$(echo $* | tr + " ")

dev.restart.%: ## Restart specific services, separated by plus-signs.
	docker-compose restart $$(echo $* | tr + " ")

dev.kill: ## Kill all services.
	(test -d .docker-sync && docker-sync stop) || true ## Ignore failure here
	docker-compose stop

dev.kill.%: ## Kill specific services, separated by plus-signs.
	docker-compose kill $$(echo $* | tr + " ")

dev.rm-stopped: ## Remove stopped containers. Does not affect running containers.
	docker-compose rm --force

dev.down.%: ## Stop and remove specific services, separated by plus-signs.
	docker-compose rm --force --stop $$(echo $* | tr + " ")

dev.down: ## Stop and remove all service containers and networks
	(test -d .docker-sync && docker-sync clean) || true ## Ignore failure here
	docker-compose down

dev.destroy: ## Remove all devstack-related containers, networks, and volumes
	$(WINPTY) bash ./destroy.sh

#dev.logs:  ## View logs from containers running in detached mode.
	#docker-compose logs -f

dev.logs.%: ## View the logs of the specified service container
	docker-compose logs -f --tail=500 $*

dev.validate: ## Validate the devstack configuration
	docker-compose config

dev.backup: dev.up.mysql+mongo+elasticsearch ## Write all data volumes to the host.
	docker run --rm --volumes-from $$(make -s dev.print-container.mysql) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zcvf /backup/mysql.tar.gz /var/lib/mysql
	docker runsql --rm --volumes-from $$(make -s dev.print-container.mongo) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zcvf /backup/mongo.tar.gz /data/db
	docker run --rm --volumes-from $$(make -s dev.print-container.elasticsearch) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zcvf /backup/elasticsearch.tar.gz /usr/share/elasticsearch/data

dev.restore: dev.up.mysql+mongo+elasticsearch ## Restore all data volumes from the host. WARNING: THIS WILL OVERWRITE ALL EXISTING DATA!
	docker run --rm --volumes-from $$(make -s dev.print-container.mysql) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zxvf /backup/mysql.tar.gz
	docker run --rm --volumes-from $$(make -s dev.print-container.mongo) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zxvf /backup/mongo.tar.gz
	docker run --rm --volumes-from $$(make -s dev.print-container.elasticsearch) -v $$(pwd)/.dev/backups:/backup debian:jessie tar zxvf /backup/elasticsearch.tar.gz

dev.shell.analyticspipeline: ## Run a shell on the analytics pipeline container
	docker-compose exec analyticspipeline env TERM=$(TERM) /edx/app/analytics_pipeline/devstack.sh open

dev.shell.credentials: ## Run a shell on the credentials container
	docker-compose exec credentials env TERM=$(TERM) bash -c 'source /edx/app/credentials/credentials_env && cd /edx/app/credentials/credentials && /bin/bash'

dev.shell.discovery: ## Run a shell on the discovery container
	docker-compose exec discovery env TERM=$(TERM) /edx/app/discovery/devstack.sh open

dev.shell.ecommerce: ## Run a shell on the ecommerce container
	docker-compose exec ecommerce env TERM=$(TERM) /edx/app/ecommerce/devstack.sh open

dev.shell.e2e: ## Start the end-to-end tests container with a shell
	docker run -it --network=${COMPOSE_PROJECT_NAME:-devstack}_default -v ${DEVSTACK_WORKSPACE}/edx-e2e-tests:/edx-e2e-tests -v ${DEVSTACK_WORKSPACE}/edx-platform:/edx-e2e-tests/lib/edx-platform --env-file ${DEVSTACK_WORKSPACE}/edx-e2e-tests/devstack_env edxops/e2e env TERM=$(TERM) bash

dev.shell.registrar: ## Run a shell on the registrar site container
	docker-compose exec registrar env TERM=$(TERM) /edx/app/registrar/devstack.sh open

dev.shell.xqueue: ## Run a shell on the XQueue container
	docker-compose exec xqueue env TERM=$(TERM) /edx/app/xqueue/devstack.sh open

dev.shell.lms: ## Run a shell on the LMS container
	docker-compose exec lms env TERM=$(TERM) /edx/app/edxapp/devstack.sh open

dev.shell.lms-watcher: ## Run a shell on the LMS watcher container
	docker-compose exec lms_watcher env TERM=$(TERM) /edx/app/edxapp/devstack.sh open

dev.shell.studio: ## Run a shell on the Studio container
	docker-compose exec studio env TERM=$(TERM) /edx/app/edxapp/devstack.sh open

dev.shell.studio-watcher: ## Run a shell on the studio watcher container
	docker-compose exec studio_watcher env TERM=$(TERM) /edx/app/edxapp/devstack.sh open

dev.shell.xqueue_consumer: ## Run a shell on the XQueue consumer container
	docker-compose exec xqueue_consumer env TERM=$(TERM) /edx/app/xqueue/devstack.sh open

dev.shell.marketing: ## Run a shell on the marketing site container
	docker-compose exec marketing env TERM=$(TERM) bash -c 'cd /edx/app/edx-mktg/edx-mktg; exec /bin/bash -sh'

dev.shell.%: ## Run a shell on the specified service container.
	docker-compose exec $* /bin/bash

dev.dbshell.%: ## Run a SQL shell on the given service's database.
	docker-compose exec mysql bash -c "mysql $*"

%-update-db: ## Run migrations for the specified service container
	docker-compose exec $* bash -c 'source /edx/app/$*/$*_env && cd /edx/app/$*/$*/ && make migrate'

studio-update-db: ## Run migrations for the Studio container
	docker-compose exec studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && paver update_db'

lms-update-db: ## Run migrations LMS container
	docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && paver update_db'

update-db: | $(DB_MIGRATION_TARGETS) ## Run the migrations for DEFAULT_SERVICE_LIST

forum-restart-devserver: ## Kill the forum's Sinatra development server. The watcher process will restart it.
	docker-compose exec forum bash -c 'kill $$(ps aux | grep "ruby app.rb" | egrep -v "while|grep" | awk "{print \$$2}")'

%-attach: ## Attach to the specified service container process to use the debugger & see logs.
	docker attach "$$(make --silent dev.print-container.$*)"

lms-restart: lms-restart-devserver

studio-restart: studio-restart-devserver

xqueue-restart: xqueue-restart-devserver

%-restart-devserver: ## Kill a service's Django development server. The watcher process should restart it.
	docker-compose exec $* bash -c 'kill $$(ps aux | egrep "manage.py ?\w* runserver" | egrep -v "while|grep" | awk "{print \$$2}")'

xqueue_consumer-restart: ## Kill the XQueue development server. The watcher process will restart it.
	docker-compose exec xqueue_consumer bash -c 'kill $$(ps aux | grep "manage.py run_consumer" | egrep -v "while|grep" | awk "{print \$$2}")'

%-static: ## Rebuild static assets for the specified service container
	docker-compose exec $* bash -c 'source /edx/app/$*/$*_env && cd /edx/app/$*/$*/ && make static'

lms-static: ## Rebuild static assets for the LMS container
	docker-compose exec lms bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && paver update_assets lms'

studio-static: ## Rebuild static assets for the Studio container
	docker-compose exec studio bash -c 'source /edx/app/edxapp/edxapp_env && cd /edx/app/edxapp/edx-platform/ && paver update_assets studio'

static: | credentials-static discovery-static ecommerce-static lms-static studio-static ## Rebuild static assets for all service containers

e2e-tests: ## Run the end-to-end tests against the service containers
	docker run -t --network=${COMPOSE_PROJECT_NAME:-devstack}_default -v ${DEVSTACK_WORKSPACE}/edx-e2e-tests:/edx-e2e-tests -v ${DEVSTACK_WORKSPACE}/edx-platform:/edx-e2e-tests/lib/edx-platform --env-file ${DEVSTACK_WORKSPACE}/edx-e2e-tests/devstack_env edxops/e2e env TERM=$(TERM)  bash -c 'paver e2e_test --exclude="whitelabel\|enterprise"'

validate-lms-volume: ## Validate that changes to the local workspace are reflected in the LMS container
	touch $(DEVSTACK_WORKSPACE)/edx-platform/testfile
	docker-compose exec -T lms ls /edx/app/edxapp/edx-platform/testfile
	rm $(DEVSTACK_WORKSPACE)/edx-platform/testfile

vnc-passwords: ## Get the VNC passwords for the Chrome and Firefox Selenium containers
	@docker-compose logs chrome 2>&1 | grep "VNC password" | tail -1
	@docker-compose logs firefox 2>&1 | grep "VNC password" | tail -1

devpi-password: ## Get the root devpi password for the devpi container
	docker-compose exec devpi bash -c "cat /data/server/.serverpassword"

analytics-pipeline-devstack-test: ## Run analytics pipeline tests in travis build
	docker-compose exec -u hadoop -T analyticspipeline bash -c 'sudo chown -R hadoop:hadoop /edx/app/analytics_pipeline && source /edx/app/hadoop/.bashrc && make develop-local && make docker-test-acceptance-local ONLY_TESTS=edx.analytics.tasks.tests.acceptance.test_internal_reporting_database && make docker-test-acceptance-local ONLY_TESTS=edx.analytics.tasks.tests.acceptance.test_user_activity'

hadoop-application-logs-%: ## View hadoop logs by application Id
	docker-compose exec nodemanager yarn logs -applicationId $*

# Provisions studio, ecommerce, and marketing with course(s) in test-course.json
# Modify test-course.json before running this make target to generate a custom course
dev.create-test-course: ## NOTE: marketing course creation is not available for those outside edX
	$(WINPTY) bash ./course-generator/create-courses.sh --studio --ecommerce --marketing course-generator/test-course.json

# Run the course json builder script and use the outputted course json to provision studio, ecommerce, and marketing
# Modify the list of courses in build-course-json.sh beforehand to generate custom courses
dev.build-courses: ## NOTE: marketing course creation is not available for those outside edX
	$(WINPTY) bash ./course-generator/build-course-json.sh course-generator/tmp-config.json
	$(WINPTY) bash ./course-generator/create-courses.sh --studio --ecommerce --marketing course-generator/tmp-config.json
	rm course-generator/tmp-config.json

dev.stats: ## Get per-container CPU and memory utilization data
	docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

dev.feature-toggle-state: ## Gather the state of feature toggles configured for various IDAs
	$(WINPTY) bash ./gather-feature-toggle-state.sh

check-memory: ## Check if enough memory has been allocated to Docker
	@if [ `docker info --format '{{.MemTotal}}'` -lt 2095771648 ]; then echo "\033[0;31mWarning, System Memory is set too low!!! Increase Docker memory to be at least 2 Gigs\033[0m"; fi || exit 0

selfcheck: ## check that the Makefile is well-formed
	@echo "The Makefile is well-formed."
