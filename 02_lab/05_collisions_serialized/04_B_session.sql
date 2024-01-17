select * from test_table;
update test_table set test_column = 'update_from_session_b' where id = 2;
insert into test_table(test_column) values('insert_from_session_b');
select * from test_table;