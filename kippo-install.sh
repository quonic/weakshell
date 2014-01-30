cd ~/
wget http://kippo.googlecode.com/files/kippo-0.8.tar.gz
tar xzf kippo-0.8.tar.gz
iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
adduser kippo
mkdir /home/kippo/
cp -R ~/kippo-0.8/* /home/kippo/
cd /home/kippo/
utils/createfs.py > fs.pickle
utils/passdb.py data/pass.db add password
utils/passdb.py data/pass.db add senthil
utils/passdb.py data/pass.db add unixmen
adduser kippo
chown -R kippo:kippo /home/kippo/
cd /etc/init.d
chmod +x kippo
touch kippo
cat > kippo << EOF
#! /bin/bash

HOMEDIR=/home/kippo
USER=kippo

PIDFILE=kippo.pid


# Source function library.
. /etc/init.d/functions

if [ ! -f "${HOMEDIR}/kippo.cfg" ]; then
    exit 6
fi

CWD=$(pwd)

start() {
    # Start daemons.
    echo -n "Starting kippo..."
    cd "${HOMEDIR}"

    # Check if running
    if [ -f "${HOMEDIR}/${PIDFILE}" ]; then
        RES=`ps ax | grep twistd | grep `cat "${HOMEDIR}/${PIDFILE}"``
        if [ ! -z "${RES}" ]; then
            echo "failed - kippo already running (PID `cat "${HOMEDIR}/${PIDFILE}"`)"
            exit 3
        fi
    fi
    # run it
    su -c "twistd -y kippo.tac -l log/kippo.log --pidfile ${PIDFILE}" -s /bin/sh ${USER} 1>&2 > /dev/null
    cd "${CWD}"
    RES=`ps ax | grep twistd | grep `cat "${HOMEDIR}/${PIDFILE}"``
    if [ ! -z "${RES}" ]; then
        echo "done. (PID `cat "${HOMEDIR}/${PIDFILE}"`)"
    else
        echo "failed."
    fi
    return 0
}

stop() {
    # Stop daemons.
    echo -n "Stopping kippo..."

    # only if pid file exists
    if [ -f "${HOMEDIR}/${PIDFILE}" ]; then
        RES=`ps ax | grep twistd | grep `cat "${HOMEDIR}/${PIDFILE}"``

        # only if process is active
        if [ ! -z "${RES}" ]; then
            kill -9 `cat "${HOMEDIR}/${PIDFILE}"`
            echo "done. (PID `cat "${HOMEDIR}/${PIDFILE}"`)"
            RES=`ps ax | grep twistd | grep `cat "${HOMEDIR}/${PIDFILE}"``

            # remove pid file if no longer active
            if [ -z "${RES}" ]; then
                rm "${HOMEDIR}/${PIDFILE}"
            else
                echo "Error: kippo termination failed."
                exit 6
            fi
        else
            echo "kippo is not running."
        fi
    else
        echo "kippo is not running."
    fi
    return 0
}


status() {
    ST="kippo is not running"
    if [ -f "${HOMEDIR}/${PIDFILE}" ]; then
        RES=`ps ax | grep twistd | grep `cat "${HOMEDIR}/${PIDFILE}"``
        if [ ! -z "${RES}" ]; then
            ST="kippo is running (PID `cat "${HOMEDIR}/${PIDFILE}"`)"
        fi
    fi
    echo ${ST}
    return 0
}


# See how we were called.
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart|reload|force-reload)
        stop
        start
        ;;
    *)
        echo $"Usage: $0 {start|stop|restart|reload|force-reload|status}"
        ;;
esac

exit 0
EOF
