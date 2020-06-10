# TODO explain

.PHONY: analytics-pipeline-shell backup build-courses create-test-course \
        destroy dev.provision.analytics_pipeline dev.up.all \
        dev.up.analytics_pipeline down feature-toggle-state healthchecks logs \
        provision pull pull.analytics_pipeline pull.xqueue restore stats stop \
        stop.all stop.analytics_pipeline stop.watchers stop.xqueue validate


#####################################################################
# Support prefix form:
# $service-$action instead of dev.$action.$services
#####################################################################

$(addsuffix -logs, $(ALL_SERVICES)): %-logs: dev.logs.%

$(addsuffix -shell, $(ALL_SERVICES)): %-shell: dev.shell.%

$(addsuffix -dbshell, $(DB_SERVICES)): %-dbshell: dev.dbshell.%

$(addsuffix -migrate, $(DB_SERVICES)): %-migrate: dev.migrate.%

$(addsuffix -restart-service, $(DB_SERVICES)): %-restart-service: dev.restart-service.%

$(addsuffix -restart-devserver, $(ALL_SERVICES)): %-restart-devserver: dev.restart-devserver.%

$(addsuffix -attach, $(ALL_SERVICES)): %-attach: dev.attach.%


#####################################################################
# Support for commands that were renamed.
#####################################################################

$(addsuffix -update-db, $(DB_SERVICES)): %-update-db: %-migrate

$(addprefix mysql-shell-, $(DB_SERVICES)): mysql-shell-%: %-dbshell

$(addprefix healthchecks., $(ALL_SERVICES)): healthchecks.%: dev.check.%

$(addprefix dev.provision.services., $(ALL_SERVICES)): dev.provision.services.%: dev.provision.%

lms-restart: dev.restart-devserver.lms

studio-restart: dev.restart-devserver.studio

xqueue-restart: dev.restart-devserver.xqueue

xqueue_consumer-restart: dev.restart-devserver.xqueue_consumer

dev.up.all: dev.up.with-watchers

stop.all: dev.stop

stop.xqueue: dev.stop.xqueue+xqueue_consumer

stop.watchers: dev.stop.lms_watcher+studio_watcher

pull.xqueue: dev.pull.without-deps.xqueue+xqueue_consumer

dev.provision.analytics_pipeline: dev.provision.services.analyticspipeline

analytics-pipeline-shell: analyticspipeline-shell

dev.up.analytics_pipeline: dev.up.analyticspipeline

pull.analytics_pipeline: dev.pull.analyticspipeline

stop.analytics_pipeline: dev.stop.namenode+datanode+resourcemanager+nodemanager+sparkmaster+sparkworker+vertica+analyticspipeline

dev.validate: dev.validate-config

dev.repo.reset: dev.reset.repos

dev.up.watchers: dev.up.lms_watcher+studio_watcher


#####################################################################
# Support commands that were not prefixed with `dev`, but now are.
#####################################################################

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

#####################################################################
# Support for miscellaneous commands.
#####################################################################
