include .env

default: up

COMPOSER_ROOT ?= /var/www/html
DRUPAL_ROOT ?= /var/www/html/web
DRUPAL_DEFAULT ?= web/sites/default

## help	:	Print commands help.
.PHONY: help
ifneq (,$(wildcard docker.mk))
help : docker.mk
	@sed -n 's/^##//p' $<
else
help : Makefile
	@sed -n 's/^##//p' $<
endif

## up	:	Start up containers.
.PHONY: up
up:
	@echo "Starting up containers for $(PROJECT_NAME)..."
	docker-compose pull
	docker-compose up -d --remove-orphans

.PHONY: mutagen
mutagen:
	mutagen-compose up

## down	:	Stop containers.
.PHONY: down
down: stop

## start	:	Start containers without updating.
.PHONY: start
start:
	@echo "Starting containers for $(PROJECT_NAME) from where you left off..."
	@docker-compose start

## restart	:	Restart containers without updating.
.PHONY: restart
restart:
	@echo "Restarting containers for $(PROJECT_NAME) ..."
	@docker-compose restart

## stop	:	Stop containers.
.PHONY: stop
stop:
	@echo "Stopping containers for $(PROJECT_NAME)..."
	@docker-compose stop

## prune	:	Remove containers and their volumes.
##		You can optionally pass an argument with the service name to prune single container
##		prune mariadb	: Prune `mariadb` container and remove its volumes.
##		prune mariadb solr	: Prune `mariadb` and `solr` containers and remove their volumes.
.PHONY: prune
prune:
	@echo "Removing containers for $(PROJECT_NAME)..."
	@docker-compose down -v $(filter-out $@,$(MAKECMDGOALS))

## ps	:	List running containers.
.PHONY: ps
ps:
	@docker ps --filter name='$(PROJECT_NAME)*'

## shell	:	Access `php` container via shell.
##		You can optionally pass an argument with a service name to open a shell on the specified container
.PHONY: shell
shell:
	docker exec -ti -e COLUMNS=$(shell tput cols) -e LINES=$(shell tput lines) $(shell docker ps --filter name='$(PROJECT_NAME)_$(or $(filter-out $@,$(MAKECMDGOALS)), 'php')' --format "{{ .ID }}") sh

## composer	:	Executes `composer` command in a specified `COMPOSER_ROOT` directory (default is `/var/www/html`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make composer "update drupal/core --with-dependencies"
.PHONY: composer
composer:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") composer --working-dir=$(COMPOSER_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## drush	:	Executes `drush` command in a specified `DRUPAL_ROOT` directory (default is `/var/www/html/web`).
##		To use "--flag" arguments include them in quotation marks.
##		For example: make drush "watchdog:show --type=cron"
.PHONY: drush
drush:
	docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT) $(filter-out $@,$(MAKECMDGOALS))

## logs	:	View containers logs.
##		You can optinally pass an argument with the service name to limit logs
##		logs php	: View `php` container logs.
##		logs nginx php	: View `nginx` and `php` containers logs.
.PHONY: logs
logs:
	@docker-compose logs -f $(filter-out $@,$(MAKECMDGOALS))

# https://stackoverflow.com/a/6273809/1826109
%:
	@:

##########################################################################
##    Specific to project
##########################################################################

BLACK        := $(shell tput -Txterm setaf 0)
RED          := $(shell tput -Txterm setaf 1)
GREEN        := $(shell tput -Txterm setaf 2)
YELLOW       := $(shell tput -Txterm setaf 3)
LIGHTPURPLE  := $(shell tput -Txterm setaf 4)
PURPLE       := $(shell tput -Txterm setaf 5)
BLUE         := $(shell tput -Txterm setaf 6)
WHITE        := $(shell tput -Txterm setaf 7)

RESET := $(shell tput -Txterm sgr0)

# Shortcut for Drush command inside the container (this allows to handle --parameter with no errors).
DRUSHCOMMAND := docker exec $(shell docker ps --filter name='^/$(PROJECT_NAME)_php' --format "{{ .ID }}") drush -r $(DRUPAL_ROOT)

## local-env	:	Rename files for local environment.
.PHONY: local-env
local-env: local-settings
	@echo "${BLUE}Copy .env.example to .env${RESET}"
	@cp -i .env.example .env && echo "${GREEN}File created.${RESET}" || echo "${RED}File not created.${RESET}"
	@echo "${BLUE}Copy docker-compose.override.example.yml docker-compose.override.yml${RESET}"
	@cp -i docker-compose.override.example.yml docker-compose.override.yml && echo "${GREEN}File created.${RESET}" || echo "${RED}File not created.${RESET}"

## local-settings : Copy the example.settings.local.php to settings.local.php in sites/default
.PHONY: local-settings
local-settings:
	@echo "Copy the custom.settings.local.php to settings.local.php in sites/default"
	@chmod 755 ${DRUPAL_DEFAULT} # Drupal set the default directory to read-only, we need to make it writable
	@cp -i web/sites/custom.settings.local.php ${DRUPAL_DEFAULT}/settings.local.php && echo "${GREEN}File created.${RESET}" || echo "${RED}File not created.${RESET}"
	@chmod 555 ${DRUPAL_DEFAULT} # Revert permissions

## fix-permissions : Allow you to change folder permissions (555 on sites/default and 777 for underneath folders)
.PHONY: fix-permissions
fix-permissions:
	@find ${DRUPAL_DEFAULT} -type d -exec chmod -v 777 {} \;
	@chmod 555 ${DRUPAL_DEFAULT}
	@chmod 444 ${DRUPAL_DEFAULT}/settings.php

## all-permissions : Allow you to change folder permissions (777 on sites/default)
.PHONY: all-permissions
all-permissions:
	@chmod 777 ${DRUPAL_DEFAULT}

## init	:	Install drupal with your code configuration set.
.PHONY: init
init:
	@echo "${BLUE}Run composer install ...${RESET}"
	make composer install
	@echo "${BLUE}Restart containers ...${RESET}"
	make restart
	@echo "${BLUE}Installing Drupal...${RESET}"
	${DRUSHCOMMAND} si minimal --account-name=${DRUPAL_INIT_ADMIN_USER_NAME} --account-pass=${DRUPAL_INIT_ADMIN_PASSWORD} --account-mail=${DRUPAL_INIT_ADMIN_EMAIL}
	@echo "${BLUE}Update site variables...${RESET}"
	${DRUSHCOMMAND} cset "system.site" uuid "45140139-be28-4fef-b13f-11d9af32205e"
	@echo "${BLUE}Run Update DB hooks - Drush updb ...${RESET}"
	${DRUSHCOMMAND} updb
	@echo "${BLUE}Import config${RESET}"
	${DRUSHCOMMAND} cim
	@echo "${BLUE}Fix permissions ...${RESET}"
	make fix-permissions
	@echo "${BLUE}Clear cache - Drush cr ...${RESET}"
	make drush cr
	@echo "${GREEN}BOUYAKAAAA !!! Run ${RED}make website ${GREEN}to launch your website${RESET}"

## import-db	:	Save your current database, then Executes drush sql-cli<db.sql command in php container.
.PHONY: import-db
import-db:
	@echo "${BLUE}Dumping current database as a backup...${RESET}"
	@${DRUSHCOMMAND} sql-dump --result-file=../db-backup.sql
	@echo "${BLUE}Empty all tables...${RESET}"
	@${DRUSHCOMMAND} sql-drop
	@echo "${BLUE}Importing databse with drush...${RESET}"
	@${DRUSHCOMMAND} sql-cli<db.sql && echo "${GREEN}Databse Imported. You can remove the db.sql file now.${RESET}" || echo "${RED}You need a db.sql file at the root of the project.${RESET}"

## export-db	:	Save your current database, then Executes drush sql-cli<db.sql command in php container.
.PHONY: export-db
export-db:
	@echo "${BLUE}Dumping current database as a backup...${RESET}"
	@${DRUSHCOMMAND} sql-dump --result-file=../db-backup.sql && echo "${GREEN}Database Exported : db-backup.sql.${RESET}" || echo "${RED}Exporting database failed.${RESET}"

.PHONY: backup-db
backup-db:
	@echo "${BLUE}Making a backup of the database${RESET}"
	@mkdir -p backups/databases
	@${DRUSHCOMMAND} sql-dump --result-file=../backups/databases/db-backup-$(shell date +%FT%T%Z).sql && echo "${GREEN}Database successfully exported to your backups/databases directory.${RESET}" || echo "${RED}Exporting database failed.${RESET}"

## update	:	Executes some drush commands to update the database.
.PHONY: update
update: backup-db
	@echo "${BLUE}Run composer install ...${RESET}"
	make composer install
	@echo "${BLUE}Run Update DB hooks - Drush updb ...${RESET}"
	make drush updb
	@echo "${BLUE}Clear cache - Drush cr BEFORE cim ...${RESET}"
	make drush cr
	@echo "${BLUE}Import config - Drush cim ...${RESET}"
	make drush cim
	@echo "${BLUE}Clear cache - Drush cr AFTER cim ...${RESET}"
	make drush cr

.PHONY: uli
uli:
	docker-compose exec php bash -c "drush uli --uri=http://formation.loc"

## website	:	Launch website in default browser.
.PHONY: website
website:
	xdg-open http://${PROJECT_BASE_URL} || open http://${PROJECT_BASE_URL}

## pma	:	Launch PHP/MyAdmin in default browser.
.PHONY: pma
pma:
	xdg-open http://pma.${PROJECT_BASE_URL} || open http://pma.${PROJECT_BASE_URL}
