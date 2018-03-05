# Table of Contents
1. [Prerequisites](#prerequisites)
2. [How to use](#usage)
3. [MySQL](#mysql)
4. [Vault](#vault)
5. [ProxySQL](#proxysql)
6. [LDAP](#ldap)
7. [Cassandra CCM](#ccm)

# Prerequisites
this repo

Docker installed (17.09.1-ce)

# How to use <a name="usage"></a>

You probably don't want to start all of these at once.

Instead, choose the ones you want to spin up, like this:
```
docker-compose up -d app mysqlprimary mysqlreplica vault proxysql
```

Run the following to stop:
```
docker-compose down
```

Use Kitematic (recommended) or enter an example container like this:
```
docker exec -it app bash
```

# MySQL <a name="mysql"></a>

For a single node of mysql, edit the image line (line 43) as needed for version. The default is currently 5.7. To run 8.0, for example, edit the line to:
`image: dataindataout/mysql:8.0`

Then run a single node from your terminal like:
`docker-compose up -d mysqlprimary`

For two nodes set up as primary-replica, run three containers like:
```
docker-compose up -d mysqlprimary mysqlreplica ops
```

Then start mysql replication on the ops container:
`source initiate_replication.sh mysqlprimary mysqlreplica`

# Using Vault <a name="vault"></a>

## Initialize/unseal Vault
`source initiate_vault.sh`

## Hello world
```
vault write secret/admin email=blah@blah.com password=mysecretpassword
```

Output
```
Success! Data written to: secret/admin
```

`vault read secret/admin`

Output
```
Key                 Value
---                 -----
refresh_interval    768h0m0s
email               blah@blah.com
password            mysecretpassword
```

## Set up vault to save database credentials
`vault mount database`

Output
`Successfully mounted 'database' at 'database'!`

Assuming the following connection string works:
`mysql -hmysqlprimary -uroot -ppassword`

```
vault write database/config/mysql \
    plugin_name=mysql-database-plugin \
    connection_url="root:password@tcp(mysqlprimary:3306)/" \
    allowed_roles="readonly"
```

Expected output
```
The following warnings were returned from the Vault server:
* Read access to this endpoint should be controlled via ACLs as it will return the connection details as is, including passwords, if any.
```

## Set up credentials for expirable user/role
Write to roles; don't replace the name and password placeholders.

```
vault write database/roles/readonly \
    db_name=mysql \
    creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
    default_ttl="1h" \
    max_ttl="24h"
```

Output
`Success! Data written to: database/roles/readonly`

## Read from credentials to get user/pass
There is an API to do this, and all of this, programmatically.

`vault read database/creds/readonly`

Output
```
Key             Value
---             -----
lease_id        database/creds/readonly/a582cdcc-53b0-0bbb-2bf1-570926f65294
lease_duration  1h0m0s
lease_renewable true
password        A1a-w82s717qy2q26r80
username        v-root-readonly-p0p409z36t7zt4p1
```

## Test login with this user
`mysql -hmysqlprimary -uv-root-readonly-p0p409z36t7zt4p1 -pA1a-w82s717qy2q26r80`

# Using ProxySQL <a name="proxysql"></a>

## Create ProxySQL monitor user

```
source initiate_proxysql.sh
```

## Add login to ProxySQL
```
mysql -hproxysql -uadmin -padmin -P6032

insert into mysql_users (username,password) values ("v-root-readonly-p0p409z36t7zt4p1","A1a-w82s717qy2q26r80");
LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
```

## Connect via ProxySQL
`mysql -hproxysql -P3306 -uv-root-readonly-p0p409z36t7zt4p1 -pA1a-w82s717qy2q26r80`

## Do the user addition programmatically
`source create_user.sh`

# LDAP <a name="ldap"></a>

## Install LDAP packages

`source install_ldap.sh`

## Using web interface

Visit http://localhost:8080 in the browser.

Login as:
user = <i>cn=admin,dc=proxysql,dc=com</i> and password = <i>password</i>

Create two OU (groups, users), two posix accounts under groups (developer, bi), and one user account (e.g., vthompson) under users.

## Test from app server

Get IP address as needed:
```
docker inspect --format='{{ .NetworkSettings.Networks.adjacents_default.IPAddress }}' openldap

ldapwhoami -vvv -H ldap://172.18.0.5 -D cn=vthompson,ou=users,dc=proxysql,dc=com -x -wpassword
```

## Get info for this user

```
ldapsearch -LL -H ldap://172.18.0.5 -b "ou=users,dc=proxysql,dc=com" -D "cn=admin,dc=proxysql,dc=com" -w "password"
```

## Create and connect ldap backend, test

```
vault auth-enable ldap

vault auth -methods

vault write auth/ldap/config \
  url="ldap://172.18.0.5" \
  binddn="cn=admin,dc=proxysql,dc=com" \
  bindpass="password" \
  userattr="uid" \
  userdn="ou=users,dc=proxysql,dc=com" \
  discoverdn=true \
  groupdn="ou=groups,dc=proxysql,dc=com" \
  insecure_tls=true

vault write auth/ldap/groups/developer policies=developer

vault write auth/ldap/users/vthompson groups=developer

vault auth -method=ldap username=vthompson
[enter password at command prompt]
```

# Cassandra CCM <a name="ccm"></a>

CCM allows you to spin up any number of Cassandra nodes on any version. 

Here is how you can do it in a container.

```
docker-compose up -d ccm
docker exec -it ccm bash
ccm/setup.py install
ccm create test -v2.0.5 -n1 -s
ccm status
ccm node1 cqlsh
```

And now experiment!



