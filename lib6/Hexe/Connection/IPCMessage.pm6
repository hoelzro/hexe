use v6;

use JSON::Tiny;

class Hexe::Connection::IPCMessage {
    constant @base64-chars   = ( ('A' .. 'Z' ), ('a' .. 'z'), ('0' .. '9'), '+', '/');
    constant %base64-mapping = (map -> $value { @base64-chars[$value].ord => $value }, |(0 .. ^@base64-chars.elems -1).flat).hash;

    has $!command;
    has @!args;

    method new($command, *@args) {
        return self.bless(*, :$command, :@args);
    }

    submethod BUILD(:$!command, :@!args) {}

    method gist {
        return {
            :$!command,
            :@!args,
        }.gist();
    }

    method write(IO $h) {
        my $buf = to-json({
            :$!command,
            :@!args,
        }).encode;

        my $length = self!encoded-length($buf.bytes);
        $h.write($length ~ $buf);
    }

    method read(IO $h) {
        my $length = $h.read(4).decode;
           $length = self!decoded-length($length);

        my $body   = $h.read($length).decode;
           $body   = from-json($body);

        my $result = self.bless(*, |%$body);
        return $result;
    }

    method !encoded-length(Int $length is copy) {
        my @chars;

        for ( 1 .. 4 ) {
            my $value = $length +& 0x3f;
            @chars.unshift(@base64-chars[$value]);
            $length +>= 6;
        }

        return @chars.join('').encode;
    }

    method !decoded-length(Str $length) {
        my $num = 0;

        for $length.ords -> $ord {
            my $value = %base64-mapping{$ord};
            $num +<= 6;
            $num +|= $value;
        }

        return $num;
    }
}
