# НИЯУ МИФИ. Лабораторная работа №2-3 - "Базовые задачи администрирования СУБД"

> Мищенко Тимофей, Б20-505. 2024

## Работа

### 1. Выяснить, в каком месте файловой системы расположен установленный в предыдущих работах кластер баз данных PostgreSQL
У меня PostgreSQL в Docker (без прокинутого volume, что будет проблемой дальше...), и я помню что чтобы сделать данные persistent нужно прокидывать как volume директорию /var/lib/postgresql/data;

### 2. Выяснить, какие файлы хранятся в директории кластера базы данных;

Содержимое:

```
root@3a52e0d26655:/var/lib/postgresql/data# ls -l
total 80
drwx------ 1 postgres postgres    24 Jan 17 14:46 base
drwx------ 1 postgres postgres   632 Jan 17 18:30 global
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_commit_ts
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_dynshmem
-rw------- 1 postgres postgres  5743 Jan 17 14:46 pg_hba.conf
-rw------- 1 postgres postgres  2640 Jan 17 14:45 pg_ident.conf
drwx------ 1 postgres postgres    76 Jan 17 18:31 pg_logical
drwx------ 1 postgres postgres    28 Jan 17 14:45 pg_multixact
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_notify
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_replslot
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_serial
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_snapshots
drwx------ 1 postgres postgres     0 Jan 17 14:46 pg_stat
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_stat_tmp
drwx------ 1 postgres postgres     8 Jan 17 14:45 pg_subtrans
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_tblspc
drwx------ 1 postgres postgres     0 Jan 17 14:45 pg_twophase
-rw------- 1 postgres postgres     3 Jan 17 14:45 PG_VERSION
drwx------ 1 postgres postgres   124 Jan 17 14:54 pg_wal
drwx------ 1 postgres postgres     8 Jan 17 14:45 pg_xact
-rw------- 1 postgres postgres    88 Jan 17 14:45 postgresql.auto.conf
-rw------- 1 postgres postgres 29770 Jan 17 14:45 postgresql.conf
-rw------- 1 postgres postgres    36 Jan 17 14:46 postmaster.opts
-rw------- 1 postgres postgres    94 Jan 17 14:46 postmaster.pid
```

### 3. Выяснить, какой командной строкой запущен экземпляр PostgreSQL;

```
❯ ps aux | grep postgr
ne_bknn   114091  0.0  0.0 2435348 33580 pts/4   Sl+  17:45   0:00 docker run -it -e POSTGRES_PASSWORD=postgres -p5432:5432 postgres
999       114201  0.0  0.0 220048 29184 pts/0    Ss+  17:45   0:00 postgres
999       114323  0.0  0.0 220184 27812 ?        Ss   17:46   0:00 postgres: checkpointer
999       114324  0.0  0.0 220200  7652 ?        Ss   17:46   0:00 postgres: background writer
999       114326  0.0  0.0 220048 10148 ?        Ss   17:46   0:00 postgres: walwriter
999       114327  0.0  0.0 221640  8612 ?        Ss   17:46   0:00 postgres: autovacuum launcher
999       114328  0.0  0.0 221628  8228 ?        Ss   17:46   0:00 postgres: logical replication launcher
ne_bknn   138234  0.0  0.0  18124 10648 pts/5    S+   21:55   0:00 psql -U postgres -d postgres -h localhost
999       138236  0.0  0.0 222144 15716 ?        Ss   21:55   0:00 postgres: postgres postgres 172.17.0.1(33142) idle
```

Изнутри контейнера это можно узнать, сделав

```
postgresroot@3a52e0d26655:~# cat /proc/1/cmdline; echo
postgres
```

То есть не указано никаких дополнительных параметров при запуске postgres.

### 4. Выполнить штатное завершение работы сервера PostgreSQL

Начинаются приключения. Так как вольюма с `/var/lib/postgresql/data` нет, скопируем данные:

```
❯ docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED       STATUS       PORTS                                       NAMES
3a52e0d26655   postgres   "docker-entrypoint.s…"   4 hours ago   Up 4 hours   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   nervous_galileo
❯ docker cp 3a52:/var/lib/posgresql/data .
Error response from daemon: Could not find the file /var/lib/posgresql/data in container 3a52
❯ docker cp -r 3a52:/var/lib/posgresql/data .
unknown shorthand flag: 'r' in -r
See 'docker cp --help'.
❯ docker cp  3a52:/var/lib/postgresql/data .
Successfully copied 78.4MB to /home/ne_bknn/Projects/dbs_labs/.
```

Попытаемся остановить простым `kill`:

```
❯ ps aux | grep postgres
ne_bknn   114091  0.0  0.0 2435348 33580 pts/4   Sl+  17:45   0:00 docker run -it -e POSTGRES_PASSWORD=postgres -p5432:5432 postgres
999       114201  0.0  0.0 220048 29184 pts/0    Ss+  17:45   0:00 postgres
999       114323  0.0  0.0 220184 27812 ?        Ss   17:46   0:00 postgres: checkpointer 
999       114324  0.0  0.0 220200  7652 ?        Ss   17:46   0:00 postgres: background writer 
999       114326  0.0  0.0 220048 10148 ?        Ss   17:46   0:00 postgres: walwriter 
999       114327  0.0  0.0 221640  8612 ?        Ss   17:46   0:00 postgres: autovacuum launcher 
999       114328  0.0  0.0 221628  8228 ?        Ss   17:46   0:00 postgres: logical replication launcher 
ne_bknn   138234  0.0  0.0  18124 10648 pts/5    S+   21:55   0:00 psql -U postgres -d postgres -h localhost
999       138236  0.0  0.0 222144 15716 ?        Ss   21:55   0:00 postgres: postgres postgres 172.17.0.1(33142) idle
ne_bknn   139197  0.0  0.0   6556  2232 pts/6    S+   22:05   0:00 grep --color=auto --exclude-dir=.bzr --exclude-dir=CVS --exclude-dir=.git --exclude-dir=.hg --exclude-dir=.svn --exclude-dir=.idea --exclude-dir=.tox postgres
❯ sudo kill 114201
[sudo] password for ne_bknn: 
❯ docker ps # не помогло
CONTAINER ID   IMAGE      COMMAND                  CREATED       STATUS       PORTS                                       NAMES
3a52e0d26655   postgres   "docker-entrypoint.s…"   4 hours ago   Up 4 hours   0.0.0.0:5432->5432/tcp, :::5432->5432/tcp   nervous_galileo
❯ docker stop 3a52
3a52
❯ echo $?
0
❯ ls
01_lab  02_lab  03_lab  data
```

### 5. Вновь запустить экземпляр PostgreSQL вручную;

```
❯ docker run -it -v$(pwd)/data:/var/lib/postgresql/data -e POSTGRES_PASSWORD=postgres -p5432:5432 postgres

PostgreSQL Database directory appears to contain a database; Skipping initialization

2024-01-17 19:07:35.035 UTC [1] LOG:  starting PostgreSQL 16.1 (Debian 16.1-1.pgdg120+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 12.2.0-14) 12.2.0, 64-bit
2024-01-17 19:07:35.046 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2024-01-17 19:07:35.046 UTC [1] LOG:  listening on IPv6 address "::", port 5432
2024-01-17 19:07:35.138 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
2024-01-17 19:07:35.247 UTC [30] LOG:  database system was interrupted; last known up at 2024-01-17 18:31:32 UTC
2024-01-17 19:07:45.295 UTC [30] LOG:  syncing data directory (fsync), elapsed time: 10.04 s, current path: ./base/1/3164
2024-01-17 19:07:55.278 UTC [30] LOG:  syncing data directory (fsync), elapsed time: 20.02 s, current path: ./base/4/2603_fsm
2024-01-17 19:08:04.887 UTC [30] LOG:  database system was not properly shut down; automatic recovery in progress
2024-01-17 19:08:04.961 UTC [30] LOG:  redo starts at 0/2814218
2024-01-17 19:08:04.961 UTC [30] LOG:  invalid record length at 0/2814300: expected at least 24, got 0
2024-01-17 19:08:04.961 UTC [30] LOG:  redo done at 0/28142C8 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2024-01-17 19:08:05.752 UTC [28] LOG:  checkpoint starting: end-of-recovery immediate wait
2024-01-17 19:08:06.369 UTC [28] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.001 s, sync=0.184 s, total=0.850 s; sync files=2, longest=0.117 s, average=0.092 s; distance=0 kB, estimate=0 kB; lsn=0/2814300, redo lsn=0/2814300
2024-01-17 19:08:06.504 UTC [1] LOG:  database system is ready to accept connections
```

Запустилось.

### 6. Подключиться к экземпляру и проверить его работоспособность;

```
❯ psql -U postgres -d postgres -h localhost
Password for user postgres:
psql (16.1)
Type "help" for help.

postgres=# select * from users limit 10;
 id |     username     |         email          | primary_language | is_private |  password
----+------------------+------------------------+------------------+------------+------------
  2 | Airborne_Eel     | A.Eel@hotmail.com      | it               | t          | 2cv6dlwbl3
  3 | Silver_Shark     | S.Shark@protonmail.com | en               | f          | vw839tjhxh
  4 | Running_Inchworm | R.Inchworm@gmail.com   | it               | t          | 2jysbjjtqn
  5 | Northern_Frill   | N.Frill@hotmail.com    | es               | f          | 2cd2blvqaa
  6 | Lost_Agama       | L.Agama@gmail.com      | pl               | t          | wmuhi09bmv
  7 | Dirty_Buzzard    | D.Buzzard@hotmail.com  | fr               | t          | qoafeqs4bb
  8 | Bastard_Ant      | B.Ant@protonmail.com   | pl               | f          | kufkmcp8gl
  9 | Rabid_Firefly    | R.Firefly@outlook.com  | de               | t          | 5rxg6mqjpv
 10 | Machinegun_Frog  | M.Frog@outlook.com     | es               | f          | v75ixvunr2
 11 | Howling_Roach    | H.Roach@hotmail.com    | ru               | f          | 974fmb8ptu
(10 rows)
```

Данные сохранились.

### 7. Создать новую базу данных в кластере. Кто её владелец? Какие объекты в ней содержатся?

```
postgres=# create database newone;
CREATE DATABASE
postgres=# \l
                                                      List of databases
   Name    |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | ICU Locale | ICU Rules |   Access privileges
-----------+----------+----------+-----------------+------------+------------+------------+-----------+-----------------------
 newone    | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 postgres  | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 template0 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
           |          |          |                 |            |            |            |           | postgres=CTc/postgres
 template1 | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
           |          |          |                 |            |            |            |           | postgres=CTc/postgres
(4 rows)
```

Владелец - postgres, пользователь, под которым я собственно создавал базу. 

```
postgres=# \c newone;
You are now connected to database "newone" as user "postgres".
newone=# \dt
Did not find any relations.
newone=# SELECT relname
FROM pg_class
WHERE relkind = 'S'
AND relnamespace IN (
    SELECT oid
    FROM pg_namespace
    WHERE nspname NOT LIKE 'pg_%'
    AND nspname != 'information_schema'
);
 relname
---------
(0 rows)
```

Никакие?..

Очевидно нет. Например, в `\dt` неявно делает `public.*`. Попросим его этого не делать:

```
newone=# \dt *.*
                           List of relations
       Schema       |           Name           |    Type     |  Owner
--------------------+--------------------------+-------------+----------
 information_schema | sql_features             | table       | postgres
 information_schema | sql_implementation_info  | table       | postgres
 information_schema | sql_parts                | table       | postgres
 information_schema | sql_sizing               | table       | postgres
 pg_catalog         | pg_aggregate             | table       | postgres
 ...
 pg_catalog         | pg_parameter_acl         | table       | postgres
 pg_catalog         | pg_partitioned_table     | table       | postgres
 pg_catalog         | pg_policy                | table       | postgres
 pg_catalog         | pg_proc                  | table       | postgres
 ...
```

Такое же поведение c `\dn` (залистить все schema)

```
newone=# \dn
      List of schemas
  Name  |       Owner
--------+-------------------
 public | pg_database_owner
(1 row)

newone=# \dn *
            List of schemas
        Name        |       Owner
--------------------+-------------------
 information_schema | postgres
 pg_catalog         | postgres
 pg_toast           | postgres
 public             | pg_database_owner
(4 rows)
```

Tablespaces:

```
newone=# \db *
       List of tablespaces
    Name    |  Owner   | Location
------------+----------+----------
 pg_default | postgres |
 pg_global  | postgres |
(2 rows)
```

И так далее..

### 8, 9, 10

```
newone=# select * from public.users;
ERROR:  relation "public.users" does not exist
LINE 1: select * from public.users;
                      ^
newone=# CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
CREATE TABLE
newone=# insert into test_table(test_column) values("my value");
ERROR:  column "my value" does not exist
LINE 1: insert into test_table(test_column) values("my value");
                                                   ^
newone=# insert into test_table(test_column) values('my value');
INSERT 0 1
newone=# select * from test_table;
 id | test_column
----+-------------
  1 | my value
(1 row)

newone=# \c postgres;
You are now connected to database "postgres" as user "postgres".
postgres=# select * from public.test_table;
 id |      test_column
----+-----------------------
  1 | initial2
  3 | insert_from_session_b
  2 | update_from_session_b
  4 | insert_from_session_b
(4 rows)
```

## Заключение

Поднял и переподнял Postgres. Создал и попереключался между базами данных.