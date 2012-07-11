use v6;

use Hexe::EventLoop;
use Hexe::Connection;
use JSON::Tiny;

class Hexe {
    has $!connection;
    has $!loop;

    submethod BUILD {
        my %config    = self!connection-config;
        $!loop        = Hexe::EventLoop.new;
        %config<loop> = $!loop;
        $!connection  = Hexe::Connection.new(|%config);

        $!connection.listen-for(message => -> $msg {
            say $msg;
        });

        $!connection.listen-for(session-ready => {
            say 'connected!';
            $!connection.join-room('test@conference.localhost');
        });

        $!connection.listen-for(muc-message => -> $room, $msg, $is-echo {
            unless $msg.is-delayed {
                say $msg.body;
            }
        });

        $!connection.connect;
    }

    method run {
        $!loop.go;
    }

    method !connection-config {
        my $config-file = 'config.json';
        unless $config-file.IO ~~ :r {
            die "Unable to read '$config-file'";
        }
        my $config = slurp($config-file);
        return from-json($config);
    }
}
