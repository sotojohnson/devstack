# TODO explain

.PHONY: analytics-pipeline-shell backup build-courses create-test-course \
        destroy dev.provision.analytics_pipeline dev.up.all \
        dev.up.analytics_pipeline down feature-toggle-state healthchecks logs \
        provision pull pull.analytics_pipeline pull.xqueue restore stats stop \
        stop.all stop.analytics_pipeline stop.watchers stop.xqueue validate

ALIAS_MSG_COL=\033[1;34m# Bold blue
ALIAS_CMD_COL=\033[1;36m# Bold cyan
NO_COL=\033[0m

alias_%:
	@printf "$${ALIAS_MSG_COL}%s $${ALIAS_CMD_COL}%s$${NO_COL}\n" \
		'This Devstack make target is an alias to:' \
		'make $*'
	# make $*

dev.up.all: alias_dev.up.with-watchers

provision: alias_dev.provision

down: alias_dev.down

stop: alias_dev.stop

stop.all: alias_dev.stop

stop.xqueue: alias_dev.stop.xqueue+xqueue_consumer

stop.watchers: alias_dev.stop.lms_watcher+studio_watcher

pull: alias_dev.pull

pull.xqueue: alias_dev.pull.without-deps.xqueue+xqueue_consumer

backup: alias_dev.backup

restore: alias_dev.restore

validate: alias_dev.validate

destroy: alias_dev.destroy

healthchecks: alias_dev.check

healthchecks.%:
	make alias_dev.check.$*

dev.provision.analytics_pipeline: alias_dev.provision.services.analyticspipeline

analytics-pipeline-shell: alias_analyticspipeline-shell

dev.up.analytics_pipeline: alias_dev.up.analyticspipeline

pull.analytics_pipeline: alias_dev.pull.analyticspipeline

stop.analytics_pipeline: alias_dev.stop.namenode+datanode+resourcemanager+nodemanager+sparkmaster+sparkworker+vertica+analyticspipeline ## Stop all Analytics pipeline services.

stats: alias_dev.stats

feature-toggle-state: alias_dev.feature-toggle-state

create-test-course: alias_dev.create-test-course

build-courses: alias_dev.build-courses

logs: alias_dev.logs

mysql-shell-%:
	make alias_alias_dev.shell.mysql.$*
