use v6;

use Hexe::EventLoop;
use Hexe::Connection;
use JSON::Tiny;

class Hexe {
    has $.connection;
    has $!loop;

    submethod BUILD {
        my %config    = self!connection-config;
        $!loop        = Hexe::EventLoop.new;
        %config<loop> = $!loop;
        $!connection  = Hexe::Connection.new(|%config);

        $!connection.listen-for(session-ready => {
            say 'connected!';
            $!connection.join-room('test@conference.localhost');
        });

        $!connection.listen-for(muc-message => -> $room, $msg, $is-echo {
            # XXX return if
            unless $msg.is-delayed || $is-echo {
                self.*process-message($msg);
            }
        });

        # XXX passing a raw pair? a raw hash? (anonymous)
        # XXX can you splat a $pair into a hash for arguments?
        # XXX can you splat $hash?
        # XXX can we make => -> more concise?
        $!connection.listen-for(message => -> $msg {
            self.*process-message($msg);
        });

        $!connection.connect;
    }

    method run {
        self.*init();

        $!loop.go;
    }

    method nickname {
        return 'bot';
    }

    # no-op
    # intended to be overridden by plugins
    method process-message(Hexe::Stanza::Message $msg) {}

    # no-op
    # intended to be overridden by plugins
    method init {}

    method !connection-config {
        my $config-file = 'config.json';
        unless $config-file.IO ~~ :r {
            die "Unable to read '$config-file'";
        }
        my $config = slurp($config-file);
        return from-json($config);
    }
}
