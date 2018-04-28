# Table of Contents
1. [Prerequisites](#prerequisites)
2. [How to use](#usage)
3. [MySQL](#mysql)
4. [Cassandra CCM](#ccm)

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

# Cassandra CCM <a name="ccm"></a>

CCM allows you to spin up any number of Cassandra nodes on any version. 

Here is how you can do it in a container.

```
docker-compose up -d ccm
docker exec -it ccm bash
ccm/setup.py install
ccm create test -v 3.11.2 -n3 -s --root --debug
ccm status
ccm node1 cqlsh
```

And now experiment!

MySQL/Vault/ProxySQL/LDAP is now here: https://github.com/parham-pythian/bastion

Cassandra/ELK is now here: https://github.com/parham-pythian/cassandra-elk


