#!/bin/bash

# Initialize replication

mysql -hmysqlprimary -uroot -ppassword -e"create user repl@'%' identified by 'repl'; grant replication slave on *.* to repl@'%'"
mysql -hmysqlreplica -uroot -ppassword -e"change master to master_host='mysqlprimary',master_user='repl',master_password='repl'; start slave;"