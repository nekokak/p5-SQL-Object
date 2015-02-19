use strict;
use warnings;
use Test::More;
use SQL::Object qw/sql_obj/;
BEGIN { require 'tests.inc' };

subtest '_compose' => sub {
    my $sql;

    # and
    $sql = sql_obj('SQL1', [1, 2]);
    $sql->_compose('AND', 'SQL2', [3, 4]);
    test_obj $sql, 'SQL1 AND SQL2', [1, 2, 3, 4], 'and';

    # or
    $sql = sql_obj('SQL1', [1, 2]);
    $sql->_compose('OR', 'SQL2', [3, 4]);
    test_obj $sql, '(SQL1) OR (SQL2)', [1, 2, 3, 4], 'or';
    
    # empty
    $sql = sql_obj('SQL1', [1, 2]);
    $sql->_compose('', 'SQL2', [3, 4]);
    test_obj $sql, 'SQL1 SQL2', [1, 2, 3, 4], 'empty';

    # unknown operator
    $sql = sql_obj('SQL1', []);
    eval { $sql->_compose('UNKNOWN', 'SQL2', []) };
    like $@, qr/operator UNKNOWN is unknown/, 'unknown operator';

    # parse args
    $sql = sql_obj('A = :a', {a => 'a'});
    $sql->_compose('AND', 'B = :b', [ {b => 'b'} ]);
    test_obj $sql, 'A = ? AND B = ?', ['a', 'b'], 'parse args'; 
};

subtest 'methods' => sub {
    my $sql;

    # and
    $sql = sql_obj('SQL1', []);
    $sql->and('SQL2');
    test_obj $sql, 'SQL1 AND SQL2', [], 'and';

    # or
    $sql = sql_obj('SQL1', []);
    $sql->or('SQL2');
    test_obj $sql, '(SQL1) OR (SQL2)', [], 'or';

    # join
    $sql = sql_obj('SQL1', []);
    $sql->join('SQL2');
    test_obj $sql, 'SQL1 SQL2', [], 'join';
};

subtest 'methods accept hash' => sub {
    my $sql;

    # sql_obj accepts a hash
    # op() does it too
    $sql = sql_obj('A = :a', {a => 1});
    $sql->and('A IN (:b, :c)', {b => 2, c => 3});
    test_obj $sql, 'A = ? AND A IN (?, ?)', [1, 2, 3];
};

subtest 'operators' => sub {
    my ($cond1, $cond2, $cond3);

    $cond1 = sql_obj("SQL1", 1);
    $cond2 = sql_obj("SQL2", 2);
    
    # and
    $cond3 = $cond1 & $cond2;
    test_obj $cond1, "SQL1", [1], "and 1";
    test_obj $cond2, "SQL2", [2], "and 2";
    test_obj $cond3, "SQL1 AND SQL2", [1, 2], "and 3";

    # or
    $cond3 = $cond1 | $cond2;
    test_obj $cond1, "SQL1", [1], "or 1";
    test_obj $cond2, "SQL2", [2], "or 2";
    test_obj $cond3, "(SQL1) OR (SQL2)", [1, 2], "or 3";

    # join
    $cond3 = $cond1 + $cond2;
    test_obj $cond1, "SQL1", [1], "join 1";
    test_obj $cond2, "SQL2", [2], "join 2";
    test_obj $cond3, "SQL1 SQL2", [1, 2], "join 3";
};

done_testing;

