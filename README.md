## 1. Local setup

You have to use Docker for local development.

Follow this procedure in order to have your local environment up and running:

* Clone the repository: `git clone [my_repository_url]`
* Access the directory of your project: `cd formation-drupal-mars-2023`
* Create your local environment variable files: `make local-env`
* Open the `.env` file and change settings at the top for the admin user.
Also make sure that PHP_TAG environment variable is correct depending on your OS
(Linux, MacOs or Windows)
You can leave everything else as such.
If you want to change the default local port, for 8080 for instance,
make the following change `PROJECT_PORT=8080`
* RUN `make` in order to create the docker containers for the project:
* Run `make all-permissions` to avoid permissions issues
* RUN `make init` to install Drupal with your configuration. This step might last long, please be patient.
* RUN `make website` to launch your website.

## 2. Import existing database and files
* Export the database you want to have locally from your distant repository.
* Name it db.sql, and place it at the root of your project.
* Run `make import-db` in order to import the database
* You can now remove db.sql from your project.

## 3. Xdebug
* Update the environment section of the PHP container in docker-compose.override.yml
to enable Xdebug.
* Once you have done that, just set PHP_XDEBUG_REMOTE_CONNECT_BACK correctly:
PHP_XDEBUG_REMOTE_CONNECT_BACK: `0` = Xdebug `ON`
PHP_XDEBUG_REMOTE_CONNECT_BACK: `1` = Xdebug `OFF`
* RUN `make` for the value to be taken into account.
* You can also find more information at https://wodby.com/docs/1.0/stacks/php/local/#xdebug
- For linux:
  * PHP_XDEBUG: 1
  * PHP_XDEBUG_DEFAULT_ENABLE: 1
  * PHP_XDEBUG_MODE: debug
  * PHP_XDEBUG_REMOTE_CONNECT_BACK: 0
  * PHP_XDEBUG_CLIENT_PORT: 9000
  * PHP_XDEBUG_SESSION: PHPSTORM
  * PHP_IDE_CONFIG: serverName=docker-server
  * PHP_XDEBUG_REMOTE_HOST: 172.17.0.1 # Linux
- Config PHPSTORM:
  - Files/Settings/Language & Framework/PHP/Servers:
    * name: docker-server
    * host: genevaww.localhost
    * port: 9000
    * Debugger: xdebug
    * Path Mappins:
      * Projets/geneva-2021/web /var/www/html/web
      * Projets/geneva-2021/vendor /var/www/html/vendor
- Postman with xdebug:
  * ?XDEBUG_SESSION_START=11356

## 5. Make commands
Make command allow use to run commands from your command line without entering the Docker containers.
Here's the list of the main Make commands available.
You can update them in the Makefile if necessary.
* `make` : alias for `make up`, start up containers.
* `make help` : gives you the list of available commands.
* `make stop` : stop containers.
* `make ps` : list running containers.
* `make shell` : Access `php` container via shell.
* `make composer` : Executes `composer` in PHP container
* `make drush` : Executes `drush` in PHP container
* `make website` : Launch your website
* `make pma` : Launch PHPMyAdmin to manage your database
* `make update` : Executes some drush commands to update the database.
* `make fix-permissions` : Allow you to change folder permissions (555 on sites/default and 777 for underneath folders)

`Be careful`

For `make drush` and `make composer`, the syntax is different if you have to use -- or "" in the command.
Check `make help` for more details.
If you don't want to worry about this specific syntax, you can run those command from the php container.
For instance, instead of running:
`make composer "update drupal/core --with-dependencies"`
You can also run
`make shell`
`make composer update drupal/core --with-dependencies`

## 6. Additional services
* Use docker-compose.override.yml for additional services with specific containers
* For instance, uncomment the redis part if you want to have a redis container running
* The containers used are from wodby.
You can have more details about available containers at https://wodby.com/docs/1.0/stacks/drupal/containers/
* The example with all container is in the docker-compose file in https://github.com/wodby/docker4drupal
* You can also find more documentation about local set up at https://wodby.com/docs/1.0/stacks/php/local/

