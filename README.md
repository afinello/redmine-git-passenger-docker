# Redmine with Git Hosting Docker Image

Redmine Docker Image depending on offical Redmine 3.3.9-passenger Image, including pre-configured redmine-git-hosting and some additional themes.

## Image settings

This image exposes 2 ports: 

* ```3000``` for Redmine web interface 
* ```2222``` for Git SSH

and 2 volumes: 

* ```/usr/src/redmine/files``` for files storage
* ```/home/git/repositories``` for Git repositories data

## How to use

* clone this repository
* put your custom ```configuration.yml``` file to the project root folder if required
* add additional plugins into ```plugins``` directory
* build docker image (gems installation included):
    ```
    $ docker build -t [YOUR-IMAGE-NAME] .
    ```
Your image is ready for use.

The following examples using docker-compose to run redmine
* create ```docker-compose.yml```
    ```
    version: '3.1'

    services:

        web:
            image: afinello/redmine-git-passenger-docker:latest
            restart: always
            volumes:
                - ./home/redmine/files/:/usr/src/redmine/files
                - ./home/gitolite/repositories/:/home/git/repositories
            ports:
                - 3000:3000
                - 2222:2222
            environment:
                REDMINE_DB_MYSQL: mysql
                REDMINE_DB_DATABASE: redmine
                REDMINE_DB_USERNAME: redmine
                REDMINE_DB_PASSWORD: db_password
                REDMINE_PLUGINS_MIGRATE: 'true'

        mysql:
            image: mysql:5.7
            restart: always
            volumes:
                - ./mysql/data/:/var/lib/mysql
            environment:
                MYSQL_ROOT_PASSWORD: db_root_password
                MYSQL_DATABASE: redmine
                MYSQL_USER: redmine
                MYSQL_PASSWORD: db_password
    ```
* start your services
    ```
    $ docker-compose up -d
    ```

## Additional setup

After first launch edit initial Redmine-Git-Hosting plugin settings under Redmine Administration.

* point to redmine_gitolite_admin SSH keys

    ```
    /home/redmine/.ssh/redmine_gitolite_admin_id_rsa
    /home/redmine/.ssh/redmine_gitolite_admin_id_rsa.pub
    ```   
* specify Gitolite server port: 2222
* set Temporary dir for lock file and data
    ```
    /home/redmine/tmp/redmine_git_hosting
    ```
* check Hooks URL and Install Hooks
* in case of SmartHTTP usage with HTTPS behind the NGINX reverse proxy add an extra parameter to NGINX conf to preserve HTTPS protocol for Git Web
    ```
    proxy_set_header   X-Forwarded-Proto $scheme;
    ```
  for Apache:
    ```
    RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    RequestHeader set "X-Forwarded-SSL" expr=%{HTTPS}
    ```
