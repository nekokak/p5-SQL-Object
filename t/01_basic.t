use strict;
use warnings;
use Test::More;
use SQL::Object qw/sql sql_type sql_cond_in/;

subtest 'basic' => sub {
    my $sql = sql('foo.id=?',1);
    is $sql->as_sql, 'foo.id=?';
    is_deeply [$sql->bind], [qw/1/];

    $sql->and('bar.name=?','nekokak');
    is $sql->as_sql, 'foo.id=? AND bar.name=?';
    is_deeply [$sql->bind], [qw/1 nekokak/];

    $sql->or('bar.age=?', '33');
    is $sql->as_sql, 'foo.id=? AND bar.name=? OR bar.age=?';
    is_deeply [$sql->bind], [qw/1 nekokak 33/];

    $sql->add_parens;

    my $cond = sql('foo.id=?', 2);
    $sql = $sql | $cond;
    is $sql->as_sql, '(foo.id=? AND bar.name=? OR bar.age=?) OR foo.id=?';
    is_deeply [$sql->bind], [qw/1 nekokak 33 2/];

    $cond = sql('bar.name=?','tokuhirom');
    $sql = $sql | $cond;
    is $sql->as_sql, '(foo.id=? AND bar.name=? OR bar.age=?) OR foo.id=? OR bar.name=?';
    is_deeply [$sql->bind], [qw/1 nekokak 33 2 tokuhirom/];
};

subtest 'sql_type' => sub {
    my $var = 1;
    my $sql = sql('foo.id=?',sql_type(\$var, 'SQL_INTEGER'));
    is $sql->as_sql, 'foo.id=?';
    my $bind = $sql->bind;
    is $bind->[0]->value_ref, \$var;
    is $bind->[0]->value    , 1;
    is $bind->[0]->type     , 'SQL_INTEGER';
};

subtest 'sql_cond_in' => sub {
    my $sql = sql_cond_in('foo.id IN (%s)',[1,2],'SQL_INTEGER');
    is $sql->as_sql, 'foo.id IN (?,?)';
    my $bind = $sql->bind;
    is $bind->[0]->value , 1;
    is $bind->[0]->type  ,'SQL_INTEGER';
    is $bind->[1]->value , 2;
    is $bind->[1]->type  ,'SQL_INTEGER';
};

subtest 'sql and sql_cond_in' => sub {
    my $sql = sql('foo.id=?',1);
    is $sql->as_sql, 'foo.id=?';
    is_deeply [$sql->bind], [qw/1/];

    $sql = $sql | sql_cond_in('foo.id IN (%s)',[1,2])->add_parens;
    is $sql->as_sql, 'foo.id=? OR (foo.id IN (?,?))';
    is_deeply [$sql->bind], [qw/1 1 2/];
};

done_testing;

