DROP TABLE IF EXISTS test_table IF EXISTS;
CREATE TABLE test_table (id SERIAL PRIMARY KEY, test_column TEXT);
insert into test_table(test_column) values('initial');
begin transaction isolation level read committed;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
