# This Makefile exists entirely to support old targets that were once
# part of the documented Devstack interface but no longer are.
# This file allows us to remove old targets from the main Makefile
# (thus making it easier to read and making the `make help` message cleaner)
# while avoiding breaking backwards-compatibility with developers' existing workflows.

# In order to keep this file simple and predictable, please follow these rules
# when adding targets:
#  * Do not add targets with bodies. If the target cannnot be expressed using
#    solely targets from the main Makefile as dependencies, then it probably
#    does not belong here.
#  * Dependencies should be from the main Makefile, not this one.
#    That'll keep it easier for us to remove targets altogether if we wish to.
#  * Keep targets in alphabetical order.


.PHONY: analytics-pipeline-shell backup build-courses create-test-course \
        destroy dev.provision.analytics_pipeline dev.up.all \
        dev.up.analytics_pipeline down feature-toggle-state healthchecks logs \
        provision pull pull.analytics_pipeline pull.xqueue restore stats stop \
        stop.all stop.analytics_pipeline stop.watchers stop.xqueue validate

#####################################################################
# Generic tagets.
#####################################################################

$(addsuffix -update-db, $(DB_SERVICES)): %-update-db: %-migrate

$(addprefix mysql-shell-, $(DB_SERVICES)): mysql-shell-%: %-dbshell

$(addprefix healthchecks., $(ALL_SERVICES)): healthchecks.%: dev.check.%

$(addprefix dev.provision.services., $(ALL_SERVICES)): dev.provision.services.%: dev.provision.%


#####################################################################
# Non-generic tagets.
#####################################################################

lms-restart: dev.restart-devserver.lms

studio-restart: dev.restart-devserver.studio

xqueue-restart: dev.restart-devserver.xqueue

xqueue_consumer-restart: dev.restart-devserver.xqueue_consumer

dev.up.all: dev.up.with-watchers

stop.all: dev.stop

stop.xqueue: dev.stop.xqueue+xqueue_consumer

stop.watchers: dev.stop.lms_watcher+studio_watcher

pull.xqueue: dev.pull.without-deps.xqueue+xqueue_consumer

dev.provision.analytics_pipeline: dev.provision.analyticspipeline

analytics-pipeline-shell: dev.shell.analyticspipeline

dev.up.analytics_pipeline: dev.up.analyticspipeline

pull.analytics_pipeline: dev.pull.analyticspipeline

stop.analytics_pipeline: dev.stop.namenode+datanode+resourcemanager+nodemanager+sparkmaster+sparkworker+vertica+analyticspipeline

dev.validate: dev.validate-config

dev.repo.reset: dev.reset-repos

dev.up.watchers: dev.up.lms_watcher+studio_watcher

provision: dev.provision

logs: dev.logs

down: dev.down

stop: dev.stop

backup: dev.backup

restore: dev.restore

validate: dev.validate

destroy: dev.destroy

healthchecks: dev.check

pull: dev.pull

stats: dev.stats

static: dev.static

check-memory: dev.check-memory
