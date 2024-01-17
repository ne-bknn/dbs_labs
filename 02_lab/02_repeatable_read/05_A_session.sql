begin transaction isolation level repeatable read;
update test_table set test_column = 'initial2' where test_column = 'initial';
insert into test_table(test_column) values('new one');
select * from test_table;
commit;