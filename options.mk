# DEFAULT DEVSTACK OPTIONS
# Included into Makefile and exported to command environment.
# Defaults are listed in this file.
# Local git-ignored overrides can be configured by creating `options.local.mk`.
# Variables are set here with ?= to allow for overriding them on the command line.

# Folder in which we looks for repositories.
# Defaults to parent.
DEVSTACK_WORKSPACE ?= $(shell pwd)/..

# Name of Docker Compose project.
# See https://docs.docker.com/compose/reference/envvars/#compose_project_name
# Defaults to 'devstack' should OPENEDX_RELEASE not be defined.
ifdef OPENEDX_RELEASE
	COMPOSE_PROJECT_NAME ?= devstack-${OPENEDX_RELEASE}
else
	COMPOSE_PROJECT_NAME ?= devstack
endif

# increase Docker Compose HTTP timeout so that devstack provisioning does not fail in unstable networks
COMPOSE_HTTP_TIMEOUT=180

# Whether we should always copy programs to LMS cache upon LMS startup.
# If 'true', then run `make dev.cache-programs` whenever we bring up
# containers.
# Defaults to false.
ALWAYS_CACHE_PROGRAMS ?= false

# FileSystem Synchronization Strategy.
# How should we synchronize files between the host machine and the Docker containers?
# Options are 'local-mount', 'nfs', and 'docker-sync'.
# Note that 'local-mount' is the most tested and supported with edX's Devstack
# and 'docker-sync' the least.
FS_SYNC_STRATEGY ?= local-mounts

# List of all edX services.
# Separated by spaces. In alphabetical for clarity.
ALL_SERVICES ?=\
analyticspipeline \
credentials \
discovery \
ecommerce \
edx_notes_api \
forum \
frontend-app-publisher \
frontend-app-learning \
gradebook \
lms \
marketing \
program-console \
registrar \
registrar-worker \
studio \
xqueue \
xqueue_consumer

# Services that are pulled, provisioned, run, and checked by default
# when no services are specified manually.
# Separated by spaces. In alphabetical for clarity.
# Should be a subset of services listed in ALL_SERVICES.
# TODO: Re-evaluate this list and consider paring it down to a tighter core.
#       The current value was chosen such that it would not change the existing
#       Devstack behavior.
DEFAULT_SERVICES ?=\
credentials \
discovery \
ecommerce \
edx_notes_api \
forum \
frontend-app-publisher \
frontend-app-learning \
gradebook \
lms \
program-console \
registrar \
studio

# List of all services with database migrations.
# Separated by spaces. In alphabetical for clarity.
# Services must provide a Makefile target named: $(service)-update-db
# Note: This list should contain _all_ db-backed services, even if not
# configured to run; the list will be filtered later against $(DEFAULT_SERVICES)
DB_SERVICES ?=\
credentials \
discovery \
ecommerce \
lms \
registrar \
studio

# Include local overrides to options.
# You can use this file to configure your Devstack. It is ignored by git.
-include options.local.mk  # Prefix with hyphen to tolerate absence of file.
