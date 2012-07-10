package HexeHelper::Connection;

use Moose;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::XMPP::IM::Connection;
use Encode qw(encode_utf8 decode_utf8);
use JSON;
use MIME::Base64 qw(decode_base64 encode_base64);
use feature qw(say);

use namespace::clean -except => 'meta';

has connection => (
    is => 'rw',
);

has handle => (
    is      => 'rw',
    handles => [qw{
	on_error
	on_eof
    }],
);

has json => (
    is         => 'ro',
    lazy_build => 1,
);

has is_debugging => (
    is      => 'ro',
    default => 0,
);

has registrations => (
    is      => 'ro',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
	_has_registered => 'exists',
    },
);

sub _mark_as_registered {
    my ( $self, $signal_name ) = @_;

    $self->registrations->{$signal_name} = 1;
}

sub BUILDARGS {
    my ( $class, $fh ) = @_;

    my $handle = AnyEvent::Handle->new(
	fh => $fh,
    );

    return {
	handle => $handle,
    };
}

sub BUILD {
    my ( $self ) = @_;

    $self->handle->on_read(sub {
	my ( $h ) = @_;

	$self->_process_message($h);
    });
}

sub _build_json {
    my ( $self ) = @_;

    my $json = JSON->new->utf8;
    $json->pretty if $self->is_debugging;
    return $json;
}

sub _node_to_struct {
    my ( $self, $node ) = @_;

    my @children;

    foreach my $child ($node->nodes) {
        push @children, $self->_node_to_struct($child);
    }

    return {
        _tag      => $node->name,
        _text     => $node->text,
        _xmlns    => $node->namespace,
        _children => \@children,
        %{ $node->[2] }, # XXX NAUGHTY
    };
}

sub _setup_xmpp_extensions {
    my ( $self ) = @_;

    my $connection = $self->connection;

    require AnyEvent::XMPP::Ext::Disco;
    require AnyEvent::XMPP::Ext::MUC;

    my $disco = AnyEvent::XMPP::Ext::Disco->new;
    my $muc   = AnyEvent::XMPP::Ext::MUC->new(disco => $disco);

    $connection->add_extension($disco);
    $connection->add_extension($muc);
}

sub _setup_xmpp_handlers {
    my ( $self ) = @_;

    my @handlers;

    my $is_debugging = $self->is_debugging;
    my $connection   = $self->connection;

    foreach my $method ($self->meta->get_method_list) {
        next unless $method =~ /^_handle/;
        next if $method =~ /^_handle_debug/ && !$is_debugging;

        my $code   = __PACKAGE__->can($method);
        my $signal = $method;
        $signal    =~ s/^_handle_//;

        my $callback = sub {
            $_[0] = $self;

            goto &$method;
        };

        $connection->reg_cb($signal => $callback);
    }
}

sub _handle_error {
    my ( $self, $error ) = @_;

    say 'error: ' . $error->string;
}

sub _handle_debug_recv {
    my ( $self, $xml ) = @_;

    say STDERR $xml;
}

sub _handle_debug_send {
    my ( $self, $xml ) = @_;

    say STDERR $xml;
}

sub _process_command {
    my ( $self, $command, @args ) = @_;

    $command =~ s/-/_/g;

    my $method = $self->can("_command_$command");

    if($method) {
	$self->$method(@args);
    } else {
	say "Unknown command '$command'";
    }
}

sub _process_message {
    my ( $self, $h ) = @_;

    $h->push_read(chunk => 4, sub {
	my ( undef, $length ) = @_;

	$length = decode_base64($length);
	my ( $high_byte, $low_word ) = unpack('Cn', $length);
	$length = ($high_byte << 12) | $low_word;

	$h->push_read(chunk => $length, sub {
	    my ( undef, $chunk ) = @_;

	    my $json = $self->json->decode($chunk);
	    $self->_process_command($json->{'command'}, @{$json->{'args'}});
	});
    });
}

sub _command_create {
    my ( $self, %params ) = @_;

    $self->connection(AnyEvent::XMPP::IM::Connection->new(%params));
    $self->_setup_xmpp_extensions;
    $self->_setup_xmpp_handlers;
}

sub _get_converter {
    my ( $self, $type ) = @_;

    if($type->isa('AnyEvent::XMPP::IM::Delayed')) {
        return sub {
            my ( $self, $delayed ) = @_;

            my $node = $self->_node_to_struct($delayed->xml_node);

            $node->{'_type'} = 'Stanza';

            return $node;
        };
    }

    return;
}

sub _forward_signal {
    my ( $self, $signal_name, @args ) = @_;

    foreach my $arg (@args) {
        my $type = ref($arg);
        my $converter = $self->_get_converter($type);

        next unless $converter;

        $arg = $self->$converter($arg);
    }

    my $json = $self->json->encode({
	signal  => $signal_name,
	payload => \@args,
    });

    my $length  = length($json);
    my $packed  = pack('Cn', $length >> 16, $length & 0xffff);
    my $encoded = encode_base64($packed, '');

    $self->handle->push_write($encoded . $json);
}

sub _command_listen_for {
    my ( $self, $signal_name ) = @_;

    $signal_name =~ s/-/_/g;

    return if $self->_has_registered($signal_name);

    $self->_mark_as_registered($signal_name);

    $self->connection->reg_cb($signal_name, sub {
	my ( undef, @args ) = @_;

	$self->_forward_signal($signal_name, @args);
    });
}

sub _command_connect {
    my ( $self ) = @_;

    $self->connection->connect;
}

__PACKAGE__->meta->make_immutable;

1;
