package HexeHelper;

use Moose;

use AnyEvent::Socket qw(tcp_server);
use HexeHelper::Connection;
use feature qw(say);

use namespace::clean -except => 'meta';

has cond => (
    is         => 'ro',
    lazy_build => 1,
    handles    => {
        stop => 'send',
        run  => 'recv',
    },
);

has tcp_server => (
    is      => 'ro',
    builder => '_build_tcp_server',
);

has bind_address => (
    is      => 'ro',
    default => '127.0.0.1',
);

has bind_port => (
    is      => 'ro',
    default => 9001,
);

has connections => (
    is      => 'ro',
    default => sub { [] },
);

sub _build_cond {
    return AnyEvent->condvar;
}

sub _build_tcp_server {
    my ( $self ) = @_;

    return tcp_server $self->bind_address, $self->bind_port, sub {
        my ( $fh, $host, $port ) = @_;

        say "got connection from $host:$port";
        my $conn = $self->_create_connection($fh);
        push @{ $self->connections }, $conn;

        $conn->on_error(sub {
            @{ $self->connections } = grep {
                $_ != $conn
            } @{ $self->connections };
        });

        $conn->on_eof(sub {
            @{ $self->connections } = grep {
                $_ != $conn
            } @{ $self->connections };
        });
    };
}

sub _create_connection {
    my ( $self, $fh ) = @_;

    return HexeHelper::Connection->new($fh);
}

before run => sub {
    my ( $self ) = @_;

    my $host = $self->bind_address;
    my $port = $self->bind_port;

    say "Listening for connections on $host:$port";
};

__PACKAGE__->meta->make_immutable;

1;
