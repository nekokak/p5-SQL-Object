use strict;
use warnings;
use Test::More;
use SQL::Object qw(sql_obj);
BEGIN { require 'tests.inc' };

subtest 'basic' => sub {
    my $sql;

    # hash
    $sql = sql_obj('a = :a', {a => 'bind value'});
    test_obj $sql, 'a = ?', ['bind value'];

    # hash with arrayref->?,?,?...
    $sql = sql_obj('INSERT INTO t :fields VALUES :values',
        { 'fields' => [qw(field1 field2)], 'values' => [1, 'two'] } );
    test_obj $sql, 
        'INSERT INTO t (?,?) VALUES (?,?)', 
        [qw(field1 field2 1 two)];
};

subtest 'carp works' => sub {
    my $sql;
    
    # SQL has :name not found in hash
    eval { $sql = sql_obj(':missing_name', {}) };
    like $@, qr/missing_name not found in hash/;

    # hash has :name not found in SQL
    eval { $sql = sql_obj('a = :a', {a => 1, missing_name => 2}) };
    like $@, qr/missing_name not found in SQL/;
    eval { $sql = sql_obj('a = :a', {a => 1, no1 => 2, no2 => 3}) };
    like $@, qr/no1,no2 not found in SQL/;
};

done_testing;

