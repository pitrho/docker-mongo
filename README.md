# Docker MongoDB

This repository contains the configuration for building a
[MongoDB](http://docs.mongodb.org) Docker image using
[Ubuntu 14.04 LTS](http://releases.ubuntu.com/trusty/). This particular
Docker image

* has a reasonable default MongoDB configuration;
* makes it easy to override those defaults;
* makes it easy to persist your MongoDB data across container restarts;
* makes it easy to backup the MongoDB data to AWS S3.


## Building the image

Clone the repository

  	git clone https://github.com/pitrho/docker-mongo.git
  	cd docker-mongo
  	./build

De default tag for the new image is pitrho/mongo. If you want to specify a
different tag, pass the -t flag along with the tag name:

    ./build -t new/tag

Be default, the image installs version 3.0.7. If you want to install
a different version, pass the -v flag along with the version name:

    ./build -v 3.0.4


## Example usage

### Basic usage

Start the image using the default mongod.conf:

	docker run -d -p 27017:27017 pitrho/mongo


The first time that you run your container, a new admin user with all
privileges will be created in with a random password against the admin database.
To get the password, check the logs of the container by running:

    docker logs <CONTAINER_ID>

You will see an output like the following:

    ========================================================================
    You can now connect to this MongoDB server using:

        mongo admin -u admin -p 5C8NaEWhbvaM --host <host> --port <port>

    Please remember to change the above password as soon as possible!
    ========================================================================

In this case, `5C8NaEWhbvaM` is the password allocated to the `admin` user.

## Changing the database user and password

Instead of using the default admin user and the auto-generate password, you can
use custom values. This can be done by passing environment variables MONGO_USER
and MONGO_PASS.

  	docker run -d -p 27017:27017 -e MONGO_USER=user -e MONGO_PASS=pass pitrho/mongo

## Passing extra configuration to start the mongodb server

To pass additional settings to `mongodb`, you can use environment variable
`EXTRA_OPTS`.

  	docker run -d -p 27017:27017 -e EXTRA_OPTS="--other-options-here" pitrho/mongo


## Database data and volumes

This image does not enforce any volumes on the user. Instead, it is up to the
user to decide how to create any volumes to store the data. Docker has several
ways to do this. More information can be found in the Docker
[user guide](https://docs.docker.com/userguide/dockervolumes/).

Note that the default path where the data is stored inside the container is at
/data/db. You can mount a volume at this location to create external
backups.

## Database backups

This image introduces a mechanism for creating and storing backups on Amazon S3.
The backups can be run manually or using an internal cron schedule.

To run the backups manually, do:

    docker run -e AWS_ACCESS_KEY_ID=keyid -e AWS_SECRET_ACCESS_KEY=secret -e AWS_DEFAULT_REGION=region -e S3_BUCKET=path/to/bucket /backup.sh

To run the backups on a cron schedule (e.g every day at 6 am), do:

    docker run -d -e AWS_ACCESS_KEY_ID=keyid -e AWS_SECRET_ACCESS_KEY=secret -e AWS_DEFAULT_REGION=region -e S3_BUCKET=path/to/bucket -e CRON_TIME="0 6 * * * root"

If you want to backup a specific database, you can pass the database name using
the environment variable MONGO_DB.


## License

MIT. See the LICENSE file.


## Contributors

* [Alejandro Mesa](https://github.com/alejom99)
* [Gilman Callsen](https://github.com/callseng)
