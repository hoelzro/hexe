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
        $!connection  = Hexe::Connection.new;
    }

    method run {
        $!loop.go;
    }
}
