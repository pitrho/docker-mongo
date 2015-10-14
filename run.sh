#!/bin/bash

set -e

CMD="/usr/bin/mongod ${EXTRA_OPTS}"

RemoveLock()
{
    lockfile=/data/db/mongod.lock
    if [ -f $lockfile ]; then
        rm $lockfile
    fi
}

CreateUser()
{
    RemoveLock

    if [[ $EXTRA_OPTS == *"--smallfiles"* ]]; then
        $CMD &
    else
        $CMD --smallfiles &
    fi

    RET=1
    while [[ RET -ne 0 ]]; do
      echo "=> Waiting for confirmation of MongoDB service startup"
      sleep 5
      mongo admin --eval "help" >/dev/null 2>&1
      RET=$?
    done

    USER=${MONGO_USER:=admin}
    PASS=${MONGO_PASS:-$(pwgen -s 12 1)}
    SHOW_PWD=$( [ ${MONGO_PASS} ] && echo false || echo true )
    _word=$( [ ${MONGO_PASS} ] && echo "preset" || echo "random" )
    echo "=> Creating admin user with a ${_word} password"
    mongo admin --eval "db.createUser({user: '$USER', pwd: '$PASS', roles:[{role:'root',db:'admin'}]});"
    mongo admin --eval "db.shutdownServer();"
    touch /data/db/.pwd_set
    if [ "$SHOW_PWD" = true ]; then
        echo "========================================================================"
        echo "You can now connect to this MongoDB server using:"
        echo ""
        echo "    mongo admin -u $USER -p $PASS --host <host> --port <port>"
        echo ""
        echo "Please remember to change the above password as soon as possible!"
        echo "========================================================================"
    fi
}

if [ ! -f /data/db/.pwd_set ]; then
    CreateUser
fi

# Set backup schedule
if [ -n "${CRON_TIME}" ]; then
    exec /enable_backups.sh
fi

RemoveLock

exec $CMD
