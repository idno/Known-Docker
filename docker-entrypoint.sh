#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
  tar cf - --one-file-system -C /usr/src/known . | tar xf -
  chown -R root:www-data /var/www/html
  chmod -R 650 /var/www/html
  chmod -R 770 /var/www/html/Uploads
fi

for ((i=0;i<10;i++))
do
  DB_CONNECTABLE=$(mysql -uroot -p${DB_ENV_MYSQL_ROOT_PASSWORD} -hdb -e 'status' >/dev/null 2>&1; echo "$?")
  if [[ DB_CONNECTABLE -eq 0 ]]; then
    break
  fi
  sleep 5
done

if [[ $DB_CONNECTABLE -eq 0 ]]; then
  DB_EXISTS=$(mysql -uroot -p${DB_ENV_MYSQL_ROOT_PASSWORD} -hdb -e "SHOW DATABASES LIKE '"known"';" 2>&1 |grep "known" > /dev/null ; echo "$?")

  if [[ DB_EXISTS -eq 1 ]]; then
    echo "=> Creating database known"
    RET=$(mysql -uroot -p${DB_ENV_MYSQL_ROOT_PASSWORD} -hdb -e "CREATE DATABASE known")
    if [[ RET -ne 0 ]]; then
      echo "Cannot create database for known"
      exit RET
    fi
    echo "=> Loading initial database data to known"
    RET=$(mysql -uroot -p${DB_ENV_MYSQL_ROOT_PASSWORD} -hdb known < /var/www/html/schemas/mysql/mysql.sql)
    if [[ RET -ne 0 ]]; then
      echo "Cannot load initial database data for known"
      exit RET
    fi
    echo "=> Done!"
  else
    echo "=> Skipped creation of database known it already exists."
  fi
else
  echo "Cannot connect to Mysql"
  exit $DB_CONNECTABLE
fi

# Environment creation
echo "filesystem = 'local'"         > /var/www/html/config.ini
echo "uploadpath = '/var/www/html/Uploads'" >> /var/www/html/config.ini
echo "database = 'MySQL'"          >> /var/www/html/config.ini
echo "dbname = 'known'"       >> /var/www/html/config.ini
echo "dbhost = 'db'"       >> /var/www/html/config.ini
echo "dbuser = 'root'"       >> /var/www/html/config.ini
echo "dbpass = '${DB_ENV_MYSQL_ROOT_PASSWORD}'"       >> /var/www/html/config.ini
echo "smtp_host = ${MAIL_HOST}"    >> /var/www/html/config.ini
echo "smtp_port = ${MAIL_PORT}"    >> /var/www/html/config.ini
echo "smtp_username = ${MAIL_USER}" >> /var/www/html/config.ini
echo "smtp_password = ${MAIL_PASS}" >> /var/www/html/config.ini
echo "smtp_secure = ${MAIL_SECURE}" >> /var/www/html/config.ini

exec "$@"
