package SQL::Object;
use strict;
use warnings;
use utf8;
use Exporter qw/import/;

our @EXPORT_OK = qw/sql sql_type sql_cond_in/;

use overload
    '&' => sub { $_[0]->compose_and($_[1]) },
    '|' => sub { $_[0]->compose_or($_[1])  },
    fallback => 1
;

our $VERSION = '0.01';

sub sql {
    my ($sql, $bind) = @_;
    $bind = [$bind] unless ref($bind) eq 'ARRAY';
    SQL::Object->new(sql => $sql, bind => $bind);
}

sub sql_cond_in {
    my ($sql, $bind, $sql_type) = @_;

    my @bind;
    if ($sql_type) {
        for my $val (@{$bind}) {
            push @bind, SQL::Object::Type->new(value_ref => \$val, type => $sql_type);
        }
    } else {
        @bind = @{$bind};
    }

    SQL::Object->new(
        sql  => sprintf($sql, substr('?,' x scalar(@{$bind}), 0, -1)),
        bind => \@bind,
    );
}

sub sql_type {
    my ($value_ref, $type) = @_;
    SQL::Object::Type->new(value_ref => $value_ref, type => $type);
}

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub _compose {
    my ($self, $op, $sql, $bind) = @_;

    $self->{sql} = $self->{sql} . " $op " . $sql;
    $self->{bind} = [@{$self->{bind}}, @$bind];
    $self;
}

sub and {
    my ($self, $sql, @bind) = @_;
    $self->_compose('AND', $sql, \@bind);
}

sub or {
    my ($self, $sql, @bind) = @_;
    $self->_compose('OR', $sql, \@bind);
}

sub compose_and {
    my ($self, $other) = @_;
    $self->and($other->{sql}, @{$other->{bind}});
}

sub compose_or  {
    my ($self, $other) = @_;
    $self->or($other->{sql}, @{$other->{bind}});
}

sub add_parens {
    my $self = shift;
    $self->{sql} = '('.$self->{sql}.')';
    $self;
}

sub as_sql { $_[0]->{sql} }
sub bind   { wantarray ? @{$_[0]->{bind}} : $_[0]->{bind} }

package # hide from PAUSE
     SQL::Object::Type;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {%args}, $class;
}

sub value     { ${$_[0]->{value_ref}} }
sub value_ref { $_[0]->{value_ref}    }
sub type      { $_[0]->{type}         }

1;
__END__

=head1 NAME

SQL::Object - Yet another SQL condition builder

=head1 SYNOPSIS

    use SQL::Object qw/sql sql_cond_in/;
    
    my $sql = sql('foo.id=?',1);
    $sql->as_sql; # 'foo.id=?'
    $sql->bind;   # qw/1/
    $sql->and('foo.name=?','nekokak');
    $sql->as_sql; # 'foo.id=? AND foo.name=?'
    $sql->bind;   # qw/1 nekokak/
    $sql->add_parens;
    $sql->as_sql; # ('foo.id=? AND foo.name=?')
    
    my $other_cond = sql('foo.id=?', 2);
    $other_cond->and('foo.name=?','tokuhirom');
    $other_cond->add_parens;
    $other_cond->as_sql; # ('foo.id=? AND foo.name=?')
    
    $sql = $sql | $other_cond; # $sql->compose_or($other_cond)
    $sql->as_sql; # ('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')
    $sql->bind;   # qw/1 nekokak 2 tokuhirom/

    $sql = $sql | sql_cond_in('foo.id IN (%s)',[1,2])->add_parens;
    $sql->as_sql; # (('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')) OR (foo.id IN (?,?))
    $sql->bind;   # qw/1 nekokak 2 tokuhirom 1 2/

    $sql->add_parens;
    $sql = $sql & sql('baz.name=?','lestrrat'); # $sql->compose_and(sql('baz.name=?','lestrrat'))
    $sql->as_sql; # ((('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')) OR (foo.id IN (?,?))) AND baz.name=?

=head1 DESCRIPTION

SQL::Object is raw level SQL condition maker

=head1 METHODS

=head2 my $sql = sql($stmt, $bind)

create SQL::Object's instance.

=head2 my $sql = sql_cond_in($stmt, $bind [,$sql_type_str]);

create SQL::Object's instance.

It is sweet that makes IN condition SQL query.

=head2 my $sql_type = sql_type(\$val, SQL_VARCHAR)

create SQL::Object::Type's instance

see L</SQL::Object::Type>

=head2 my $sql = SQL::Object->new(sql => $sql, bind => \@bind);

create SQL::Object's instance

=head2 $sql = $sql->and($sql, @bind)

compose sql. operation 'ADN'.

=head2 $sql = $sql->or($sql, @bind)

compose sql. operation 'OR'.

=head2 $sql = $sql->compose_and(sql($sql, $bind))

compose sql object. operation 'AND'.

=head2 $sql = $sql->compose_or(sql($sql, $bind))

compose sql object. operation 'OR'.

=head2 $sql->add_parens()

bracket off current SQL.

=head2 $sql->as_sql()

get sql statement.

=head2 $sql->bind()

get sql bind variables.

=head1 SQL::Object::Type

SQL::Object:Type is SQL Types wrapper.

=head2 my $val = $sql_type->value()

return setting dereferenced value.

=head2 my $val_ref = $sql_type->value_ref()

return setting value reference.

=head2 my $sql_type = $sql_type->type()

return setting SQLType.

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

