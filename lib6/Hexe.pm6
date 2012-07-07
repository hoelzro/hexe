use v6;

use Hexe::EventLoop;
use Hexe::Connection;

class Hexe {
    has $!connection;
    has $!loop;

    submethod BUILD {
        my %config    = self!connection-config;
        $!loop        = Hexe::EventLoop.new;
        %config<loop> = $!loop;
        $!connection  = Hexe::Connection.new(|%config);
    }

    method run {
        $!loop.go;
    }

    method !connection-config {
        return (
            :jid<bot@localhost/Bot>,
            :password<abc123>,
        );
    }
}
