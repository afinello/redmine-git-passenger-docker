# Redmine with Git Hosting Docker Image

Redmine Docker Image depending on offical Redmine 3.3.9-passenger Image, including redmine git hosting and some additional themes.

## How to use

* clone this repository
* add additional plugins into ```plugins``` directory
* build docker image (gems installation included):
    ```
    $ docker build -t [YOUR-IMAGE-NAME] .
    ```
* your image is ready for use, the following examples using docker-compose to run redmine
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
                - 80:3000
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
