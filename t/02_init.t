use strict;
use warnings;
use Test::More;
use SQL::Object qw(sql_obj);
BEGIN { require 'tests.inc' };

subtest 'init 0' => sub {
    my $sql;

    $sql = sql_obj('SQL');
    test_obj $sql, 'SQL', [];

    $sql = sql_obj('SQL', []);
    test_obj $sql, 'SQL', [];
};

subtest 'init 1' => sub {
    my $sql;

    $sql = sql_obj('SQL', 1);
    test_obj $sql, 'SQL', [1];

    $sql = sql_obj('SQL', [1]);
    test_obj $sql, 'SQL', [1];

    # deref at bind
    my $v = 1;
    $sql = sql_obj('SQL', \$v);
    $v = 2;
    test_obj $sql, 'SQL', [2]; 
};


subtest 'init n' => sub {
    my $sql;

    $sql = sql_obj('SQL', 1, 2);
    test_obj $sql, 'SQL', [1, 2];

    $sql = sql_obj('SQL', [1, 2]);
    test_obj $sql, 'SQL', [1, 2];
};

done_testing;

