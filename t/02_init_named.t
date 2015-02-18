use strict;
use warnings;
use Test::More;
use SQL::Object qw/sql_obj/;

subtest 'carp works' => sub {
    eval { my $sql = sql_obj(':missing_name', {}) };
    like $@, qr/missing_name does not exists in hash/;
};

done_testing;

