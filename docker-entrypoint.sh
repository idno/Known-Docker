#!/bin/bash
set -e

if [ "$1" == php-fpm ]; then
  : "${KNOWN_DB_HOST:=db}"
  # if we're linked to MySQL and thus have credentials already, let's use them
  : ${KNOWN_DB_USER:=${DB_ENV_MYSQL_USER:-root}}
  if [ "$KNOWN_DB_USER" = 'root' ]; then
    : ${KNOWN_DB_PASSWORD:=$DB_ENV_MYSQL_ROOT_PASSWORD}
  fi
  : ${KNOWN_DB_PASSWORD:=$DB_ENV_MYSQL_PASSWORD}
  : ${KNOWN_DB_NAME:=${DB_ENV_MYSQL_DATABASE:-known}}

  if [ -z "$KNOWN_DB_PASSWORD" ]; then
    echo >&2 'error: missing required KNOWN_DB_PASSWORD environment variable'
    echo >&2 '  Did you forget to -e KNOWN_DB_PASSWORD=... ?'
    echo >&2
    echo >&2 '  (Also of interest might be KNOWN_DB_USER and KNOWN_DB_NAME.)'
    exit 1
  fi

  if [ ! -e '/var/www/html/version.php' ]; then
    tar cf - --one-file-system -C /usr/src/known . | tar xf -
    chown -R root:www-data /var/www/html
    chmod -R 650 /var/www/html
    chmod -R 770 /var/www/html/Uploads
  fi

  DB_CONNECTABLE=0
  echo -n 'Connecting to database'
  for ((i=0;i<10;i++))
  do
    if mysql -u${KNOWN_DB_USER} -p${KNOWN_DB_PASSWORD} -h${KNOWN_DB_HOST} -e 'status' &> /dev/null; then
      DB_CONNECTABLE=1
      echo 'Ok'
      break
    fi
    echo -n "."
    sleep 5
  done

  if [[ $DB_CONNECTABLE -eq 1 ]]; then
    DB_EXISTS=$(mysql -u${KNOWN_DB_USER} -p${KNOWN_DB_PASSWORD} -h${KNOWN_DB_HOST} -e "SHOW DATABASES LIKE '"${KNOWN_DB_NAME}"';" 2>&1 | grep ${KNOWN_DB_NAME} > /dev/null ; echo "$?")

    if [[ $DB_EXISTS -eq 1 ]]; then
      echo "=> Creating database ${KNOWN_DB_NAME}"
      RET=$(mysql -u${KNOWN_DB_USER} -p${KNOWN_DB_PASSWORD} -h${KNOWN_DB_HOST} -e "CREATE DATABASE ${KNOWN_DB_NAME}")
      if [[ $RET -ne 0 ]]; then
        echo >&2 'Cannot create database.'
        exit $RET
      fi
    else
      echo '=> Skipped creation of database for known, it already exists.'
    fi
    DB_INITIATED=$(mysql -u${KNOWN_DB_USER} -p${KNOWN_DB_PASSWORD} -h${KNOWN_DB_HOST} -e "USE '"${KNOWN_DB_NAME}"';SHOW TABLES;" 2>&1 | grep config > /dev/null ; echo "$?")

    if [[ $DB_INITIATED -eq 1 ]]; then
      echo "=> Loading initial database data to ${KNOWN_DB_NAME}"
      RET=$(mysql -u${KNOWN_DB_USER} -p${KNOWN_DB_PASSWORD} -h${KNOWN_DB_HOST} ${KNOWN_DB_NAME} < /var/www/html/schemas/mysql/mysql.sql)
      if [[ $RET -ne 0 ]]; then
        echo >&2 'Cannot load initial database data for known'
        exit $RET
      fi
    fi
    echo '=> Done!'
  else
    echo >&2 'Cannot connect to Mysql. Starting anyway...'
  fi

  if [ ! -e '/var/www/html/config.ini' ]; then
    # Environment creation
    # http://docs.withknown.com/en/latest/install/config/
    echo "filesystem = 'local'"         > /var/www/html/config.ini
    echo "uploadpath = '/var/www/html/Uploads'" >> /var/www/html/config.ini
    echo "database = 'MySQL'"          >> /var/www/html/config.ini
    echo "dbname = '${KNOWN_DB_NAME}'"       >> /var/www/html/config.ini
    echo "dbhost = '${KNOWN_DB_HOST}'"       >> /var/www/html/config.ini
    echo "dbuser = '${KNOWN_DB_USER}'"       >> /var/www/html/config.ini
    echo "dbpass = '${KNOWN_DB_PASSWORD}'"       >> /var/www/html/config.ini
    echo "smtp_host = ${MAIL_HOST}"    >> /var/www/html/config.ini
    echo "smtp_port = ${MAIL_PORT}"    >> /var/www/html/config.ini
    echo "smtp_username = ${MAIL_USER}" >> /var/www/html/config.ini
    echo "smtp_password = ${MAIL_PASS}" >> /var/www/html/config.ini
    echo "smtp_secure = ${MAIL_SECURE}" >> /var/www/html/config.ini
  fi
fi

exec "$@"
