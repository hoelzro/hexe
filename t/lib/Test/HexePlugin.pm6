use v6;

use Test;
use Hexe::EventLoop;
use Hexe::Stanza;

my sub diagr($message) {
    $*ERR.say('# ' ~ $message);
}

my class FakeConnection {
    has @.messages;

    method reset {
        @!messages = ();
    }

    method send($msg) {
        @!messages.push($msg);
    }
}

my class FakeBot {
    has $.nickname;
    has $.connection;

    submethod BUILD(:$!nickname, *%params) {
        $!connection = FakeConnection.new;
    }
}

class Test::HexePlugin {
    has $.bot-nick    = 'hexe';
    has $.my-nick     = 'tester';
    has $.send-prefix = '> ';
    has $.recv-prefix = '< ';
    has $!timeout     = 1;
    has $!test-object;
    has $!loop;
    has @!plugins;

    submethod BUILD(:@!plugins, *%params) {
        $!test-object = FakeBot.new(
            :nickname(%params<bot-nick> // 'hexe'),
        );
        for @!plugins -> $plugin {
            $!test-object does $plugin;
        }

        $!loop = Hexe::EventLoop.new;

        nextsame; # XXX this doesn't seem to set the attributes like we want...
    }

    method check-responses(@strings, Int :$timeout) {
        self!check-responses-helper(@strings, :type<chat>, :$timeout);
    }

    method check-group-responses(@strings, Int :$timeout) {
        self!check-responses-helper(@strings, :type<groupchat>, :$timeout);
    }

    method !check-responses-helper(@strings, :$type, Int :$timeout) {
        my @sent     = self!get-sent(@strings);
        my @received = self!get-received(@strings);

        $!test-object.connection.reset;
        for @sent -> $body {
            my $msg = self!make-message(:$body, :$type);
            $!test-object.process-message($msg);
        }
        self!wait-a-bit($timeout);

        my @got-messages = $!test-object.connection.messages;

        if @got-messages.elems != @received.elems {
            flunk("# received messages is not equal to our expectations (got {@got-messages.elems}, expected {@received.elems})");
            return;
        }

        for @got-messages Z @received -> $got, $expected {
            if $got.body ne $expected {
                flunk("Response mismatch!\ngot:      {$got.body}\nexpected: $expected");
                return;
            }
        }

        pass();
    }

    method !get-sent(@strings) {
        my $re = regex { ^ <$!send-prefix> };

        return @strings.grep({
            $_ ~~ $re;
        }).map({
            $_.subst($re, '');
        });
    }

    method !get-received(@strings) {
        my $re = regex { ^ <$!recv-prefix> };

        return @strings.grep({
            $_ ~~ $re;
        }).map({
            $_.subst($re, '');
        });
    }

    method !make-message(Str :$body, Str :$type) {
        my $from;
        my $to;

        if $type eq 'chat' {
            $from = $!my-nick  ~ '@localhost/test';
            $to   = $!bot-nick ~ '@localhost/test';
        } else {
            $from = 'test@conference.localhost/' ~ $!my-nick;
            $to   = 'test@conference.localhost/' ~ $!bot-nick;
        }

        return Hexe::Stanza::Message.new(
            :$body,
            :$type,
            :$from,
            :$to,
        );
    }

    method !wait-a-bit(Int $timeout) {
        my $seconds = $timeout.defined ?? $timeout !! $!timeout;

        my $timer = $!loop.timer(
            :after($seconds),
            :callback({
                $!loop.stop;
            }),
        );

        $!loop.go;
    }
}
