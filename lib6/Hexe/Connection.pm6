use Hexe::Connection::IPCMessage;

class Hexe::Connection {
    has %!callbacks;
    has $!loop;
    has $!sock;

    method new(*%params) {
        return self.bless(*);
    }

    submethod BUILD(:$!loop) {
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
        # XXX spawn child here
    }

    method listen-for(*%args) {
        for %args.pairs>>.kv -> $signal-name, $callback {
            unless %!callbacks.exists($signal-name) {
                %!callbacks{$signal-name} = [];
            }
            %!callbacks{$signal-name}.push($callback);
            self!send-command('listen-for', $signal-name);
        }
    }

    method connect {
        self!send-command('connect');
    }

    method !send-command(Str $name, *@args) {
        my $cmd = Hexe::Connection::IPCMessage.new($name, |@args);
        $cmd.write($!sock);
    }
}
