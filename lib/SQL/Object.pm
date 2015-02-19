package SQL::Object;
use strict;
use warnings;
use utf8;
use Exporter qw/import/;
use Carp;

our @EXPORT_OK = qw/sql_obj sql_type/;

use overload
    '&'  => sub { $_[0]->compose_and ($_[1]) },
    '|'  => sub { $_[0]->compose_or  ($_[1]) },
    '+'  => sub { $_[0]->compose_join($_[1]) },
    '""' => sub { $_[0]->as_sql              },
    fallback => 1
;

our $VERSION = '0.01';

sub sql_obj {
    __PACKAGE__->new(@_);
}

sub sql_type {
    my ($value_ref, $type) = @_;
    SQL::Object::Type->new(value_ref => $value_ref, type => $type);
}

sub new {
    my ($class, $sql, @bind) = @_;
	my $self = bless({}, $class);
    my ($sql2, $bind2) = $self->_parse_args($sql, \@bind);
    $self->{sql} = $sql2;
	$self->{bind} = $bind2;
	$self;
}

sub _parse_args {
    my ($self, $sql1, $bind1) = @_;
    my ($sql2, $bind2);

    $sql2 = $sql1;

    my $c = scalar @$bind1;
    my $b0 = $bind1->[0];

    if ($c == 0) {
        $bind2 = [];
    }
    elsif ($c == 1) {
        if (ref($b0) eq 'ARRAY') {
            $bind2 = $b0;
        }
        elsif (ref($b0) eq 'HASH') {
            my %named_bind = %{$b0};
			my %unused = %named_bind;

            $sql2 =~ s{:(\w+)}{
				my $name = $1;
                exists($named_bind{$name})
					or Carp::croak("$name not found in hash");
				my $value = $named_bind{$name};
				delete($unused{$name});
                if (ref($value) eq "ARRAY") {
                    push @$bind2, @$value;
                    my $tmp = join ',', map { '?' } @$value;
                     "($tmp)";
                } else {
                    push @$bind2, $value;
                    '?'
            	}
			}ge;
 			
			keys(%unused) == 0
				or Carp::croak(join(',', keys(%unused)).' not found in SQL');
        }
        # scalar or sql_type object
        else {
            $bind2 = [$b0];
        }
    }
    # @args > 1
    else {
        $bind2 = [@$bind1];
    }

    ($sql2, $bind2);
}

sub _compose {
    my ($self, $op, $sql, $bind) = @_;
    ($sql, $bind) = $self->_parse_args($sql, $bind);
    if ($op eq 'OR') {
        $self->{sql} = '('.$self->{sql}.') OR ('.$sql.')';
    } elsif ($op eq 'AND') {
        $self->{sql} = $self->{sql}.' AND '.$sql;
    } elsif ($op eq '') {
        $self->{sql} = $self->{sql}.' '.$sql;
    } else {
        Carp::croak("operator $op is unknown");
    } 
    $self->{bind} = [@{$self->{bind}}, @$bind];
    $self;
}

sub _compose_copy {
    my ($self, $op, $sql, $bind) = @_;
    my $copy = sql_obj($self->{sql}, [@{$self->{bind}}]);
    $copy->_compose($op, $sql, $bind);
}

sub and {
    my ($self, $sql, @bind) = @_;
    $self->_compose('AND', $sql, \@bind);
}

sub or {
    my ($self, $sql, @bind) = @_;
    $self->_compose('OR', $sql, \@bind);
}

sub join {
    my ($self, $sql, @bind) = @_;
    $self->_compose('', $sql, \@bind);
}

sub compose_and {
    my ($self, $other) = @_;
    $self->_compose_copy('AND', $other->{sql}, $other->{bind});
}

sub compose_or {
    my ($self, $other) = @_;
    $self->_compose_copy('OR', $other->{sql}, $other->{bind});
}

sub compose_join {
    my ($self, $other) = @_;
    $self->_compose_copy('', $other->{sql}, $other->{bind});
}

sub add_parens {
    my $self = shift;
    $self->{sql} = '('.$self->{sql}.')';
    $self;
}

sub as_sql { $_[0]->{sql} }

sub bind { 
    my $self = shift;
    my @bind = map { ref eq 'SCALAR'? $$_: $_ } @{$self->{bind}};
    @bind;
}

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

    use SQL::Object qw/sql_obj/;
    
    my $sql = sql_obj('foo.id=?',1);
    $sql->as_sql; # 'foo.id=?'
    $sql->bind;   # qw/1/
    $sql->and('foo.name=?','nekokak');
    $sql->as_sql; # 'foo.id=? AND foo.name=?'
    $sql->bind;   # qw/1 nekokak/
    $sql->as_sql; # 'foo.id=? AND foo.name=?'
    
    my $other_cond = sql_obj('foo.id=?', 2);
    $other_cond->and('foo.name=?','tokuhirom');
    $other_cond->as_sql; # 'foo.id=? AND foo.name=?'
    
    $sql = $sql | $other_cond; # $sql->compose_or($other_cond)
    $sql->as_sql; # ('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')
    $sql->bind;   # qw/1 nekokak 2 tokuhirom/

    $sql->add_parens;
    $sql = $sql & sql('baz.name=?','lestrrat'); # $sql->compose_and(sql('baz.name=?','lestrrat'))
    $sql->as_sql; # ((('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')) OR (foo.id IN (?,?))) AND baz.name=?

    $sql = sql_obj('SELECT * FROM user WHERE ') + $sql;
    $sql->as_sql; # SELECT * FROM user WHERE ((('foo.id=? AND foo.name=?') OR ('foo.id=? AND foo.name=?')) OR (foo.id IN (?,?))) AND baz.name=?

=head1 DESCRIPTION

SQL::Object is raw level SQL maker

=head1 METHODS

=head2 my $sql = sql($stmt, $bind)

create SQL::Object's instance.

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

