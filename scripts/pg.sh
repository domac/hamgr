#! /bin/sh

cp postgresql /etc/init.d/postgresql
chmod +x /etc/init.d/postgresql
chkconfig --add postgresqls
chkconfig postgresqls on