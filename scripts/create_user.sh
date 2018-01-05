#!/bin/bash

# Create vault user
vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"

IFS='|' read username password < <(vault read --format=json database/creds/readonly | jq '.data.username+"|"+.data.password' --raw-output)

# Save to proxysql
mysql -hproxysql -uadmin -padmin -P6032 -e"insert into mysql_users (username,password) values ('$username', '$password'); LOAD MYSQL USERS TO RUNTIME;SAVE MYSQL USERS TO DISK;" 

# Test user
mysql -hproxysql -P3306 -u$username -p$password -e"show databases"

echo "Works!"
echo "Your username is $username, and your password is $password. Save these in a secure location."
