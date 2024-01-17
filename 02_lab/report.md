# НИЯУ МИФИ. Лабораторная работа №2-2 - "Транзакции. Изоляция транзакций"

> Мищенко Тимофей, Б20-505. 2024

### 1. Транзакции с уровнем изоляции READ COMMITTED

Сессия А:

```
postgres=# DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level read committed;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
NOTICE:  table "test_table" does not exist, skipping
DROP TABLE
CREATE TABLE
INSERT 0 1
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)
```

Сессия B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)
```

Видим изменения внутри транзакции, не видим снаружи.

Сессия А:

```
postgres=*# ROLLBACK;
select * from test_table;
ROLLBACK
 id | test_column
----+-------------
  1 | initial
(1 row)
```

Сессия В:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
```

Откатили изменения - в сессии А вернулись к тому, что было, в сессии В ничего не изменилось.

Сессия А:

```
postgres=# CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level read committed;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
commit;
ERROR:  relation "test_table" already exists
INSERT 0 1
BEGIN
UPDATE 2
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  3 | initial2
  4 | new one
(3 rows)

COMMIT
```

Сессия В:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial2
  3 | initial2
  4 | new one
(3 rows)
```

Закоммитили транзакцию.

### 2. Транзакции с уровнем REPEATABLE READ

A:
```
postgres=# DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level repeatable read;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
DROP TABLE
CREATE TABLE
INSERT 0 1
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)
```

B:
```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)
```

A:

```
postgres=*# ROLLBACK;
select * from test_table;
ROLLBACK
 id | test_column
----+-------------
  1 | initial
(1 row)
```

B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)
```

A:
```
postgres=# begin transaction isolation level repeatable read;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
commit;
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  3 | new one
(2 rows)

COMMIT
```

B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial2
  3 | new one
(3 rows)
```

### 3. Транзакции с уровнем SERIALIZABLE

A: 

```
postgres=# DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level serializable;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
DROP TABLE
CREATE TABLE
INSERT 0 1
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)
```

B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)
```

A:

```
postgres=*# ROLLBACK;
select * from test_table;
ROLLBACK
 id | test_column
----+-------------
  1 | initial
(1 row)
```

B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)
```

A:

```
postgres=# begin transaction isolation level repeatable read;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
commit;
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  3 | new one
(2 rows)

COMMIT
```

B:

```
postgres=# select * from test_table;
 id | test_column
----+-------------
  1 | initial2
  3 | new one
(2 rows)
```

Я искренне не вижу различий. Видимо я не справился триггернуть корнеркейсы, которые в разных режимах обрабатываются по-разному.

## Коллизии транзакций

### REPEATABLE READ
A:
```
postgres=*# DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level read committed;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
DROP TABLE
CREATE TABLE
INSERT 0 1
WARNING:  there is already a transaction in progress
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)
```

B:
```
postgres=# select * from test_table;
update test_table set test_column = 'update_from_session_b' where id = 2;
insert into test_table(test_column) values('insert_from_session_b');
select * from test_table;
-- зависание, ожидает конца транзакции
```

Сразу после
A:
```
commit;
```

В сессии B происходит:

```
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)

UPDATE 1
INSERT 0 1
 id |      test_column
----+-----------------------
  1 | initial2
  2 | update_from_session_b
  3 | insert_from_session_b
(3 rows)
```

И в select в сессии A:

```
postgres=# select * from test_table;
 id |      test_column
----+-----------------------
  1 | initial2
  2 | update_from_session_b
  3 | insert_from_session_b
(3 rows)
```

В:

```
postgres=# select * from test_table;
update test_table set test_column = 'update_from_session_b' where id = 2;
insert into test_table(test_column) values('insert_from_session_b');
select * from test_table;
 id |      test_column
----+-----------------------
  1 | initial2
  2 | update_from_session_b
  3 | insert_from_session_b
(3 rows)

UPDATE 1
INSERT 0 1
 id |      test_column
----+-----------------------
  1 | initial2
  3 | insert_from_session_b
  2 | update_from_session_b
  4 | insert_from_session_b
(4 rows)
```

### SERIALIZABLE

A:

```
postgres=# DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level serializable;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
DROP TABLE
CREATE TABLE
INSERT 0 1
BEGIN
UPDATE 1
INSERT 0 1
 id | test_column
----+-------------
  1 | initial2
  2 | new one
(2 rows)
```

B:

```
postgres=# select * from test_table;
update test_table set test_column = 'update_from_session_b' where id = 2;
insert into test_table(test_column) values('insert_from_session_b');
select * from test_table;
 id | test_column
----+-------------
  1 | initial
(1 row)

UPDATE 0
INSERT 0 1
 id |      test_column
----+-----------------------
  1 | initial
  3 | insert_from_session_b
(2 rows)
```

Сессия не зависла.

A:

```
postgres=*# commit;
select * from test_table;
COMMIT
 id |      test_column
----+-----------------------
  1 | initial2
  2 | new one
  3 | insert_from_session_b
(3 rows)
```

B:

```
postgres=# select * from test_table;
update test_table set test_column = 'update_from_session_b' where id = 2;
insert into test_table(test_column) values('insert_from_session_b');
select * from test_table;
 id |      test_column
----+-----------------------
  1 | initial2
  2 | new one
  3 | insert_from_session_b
(3 rows)

UPDATE 1
INSERT 0 1
 id |      test_column
----+-----------------------
  1 | initial2
  3 | insert_from_session_b
  2 | update_from_session_b
  4 | insert_from_session_b
(4 rows)
```

## Заключение

Изучили различия между разными стратегиями обеспечения целостности при использовании транзакций.