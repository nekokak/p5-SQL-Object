use strict;
use warnings;
use Test::More;
use SQL::Object qw(sql_obj);

package MyObject;
use parent qw(SQL::Object);

sub _parse_args {
	my ($self, $sql, $bind) = @_;
	$sql = lc($sql);
	for (@$bind) {
		ref eq '' or die 'this accepts lists only';
	}
	($sql, $bind);
}

package main;

subtest 'subclass' => sub {
    my $sql;

	$sql = MyObject->new('SQL', 1, 2, 3);
	is $sql->as_sql, 'sql';
	is_deeply [$sql->bind], [1, 2, 3];

	eval { $sql  = MyObject->new('SQL', {a => 1}) };
	like $@, qr/this accepts lists only/;
};

done_testing;

