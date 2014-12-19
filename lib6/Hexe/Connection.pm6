use Hexe::Connection::IPCMessage;
use Hexe::Stanza;

class Hexe::Connection {
    has %!callbacks;
    has $!loop;
    has $!sock;

    submethod BUILD(:$!loop, *%extra-params) {
        # XXX it would be nice if this generated dynamic ports
        $!sock = IO::Socket::INET.new(:host<localhost>, :port(9001));
        $!loop.io(
            :fh($!sock),
            :poll<r>,
            :callback({
                my $msg = Hexe::Connection::IPCMessage.read($!sock);
                self!process-message($msg);
            }),
        );
        my @args = %extra-params.pairs>>.kv.list;
        my $cmd  = Hexe::Connection::IPCMessage.new(:command<create>, :@args);
        $cmd.write($!sock);
        # XXX spawn child here
    }

    method listen-for(*%args) {
        for %args.pairs>>.kv -> $signal-name, $callback {
            unless %!callbacks{$signal-name}:exists {
                %!callbacks{$signal-name} = [];
            }
            %!callbacks{$signal-name}.push($callback);
            self!send-command('listen-for', $signal-name);
        }
    }

    method connect {
        self!send-command('connect');
    }

    method join-room(Str $room-name) {
        self!send-command('join-room', 'name', $room-name);
    }

    method send(Hexe::Stanza::Message $msg) {
        my %payload;

        %payload<type> = $msg.type;
        %payload<from> = $msg.from.Str;
        %payload<to>   = $msg.to.Str;
        %payload<body> = $msg.body;

        my $payload = %payload;

        # XXX how do I just pass in %payload?
        self!send-command('send_message', $payload);
    }

    method !send-command(Str $name, *@args) {
        my $cmd = Hexe::Connection::IPCMessage.new(:command($name), :@args);
        $cmd.write($!sock);
    }

    method !convert-payload($obj) {
        # XXX can we do this with :exists?
        if $obj ~~ Hash && $obj.exists_key('_type') {
            given $obj<_type> {
                when 'Stanza' {
                    return Hexe::Stanza.create($obj);
                }
            }
        }
        return $obj;
    }

    method !process-message($msg) {
        my %hash-form = $msg.hash;

        my $signal-name = %hash-form<signal>;
        $signal-name .= subst(/_/, '-', :g);

        my @payload = %hash-form<payload>.list;
        @payload    = @payload.map({ self!convert-payload($_) });

        my $callbacks = %!callbacks{$signal-name};

        for $callbacks.list -> $callback {
            $callback.(|@payload.list); # XXX
        }
    }
}
