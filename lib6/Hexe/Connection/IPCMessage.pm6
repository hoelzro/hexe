use v6;

use JSON::Tiny;

class Hexe::Connection::IPCMessage {
    constant @base64-chars   = ( ('A' .. 'Z' ), ('a' .. 'z'), ('0' .. '9'), '+', '/');
    constant %base64-mapping = (map -> $value { @base64-chars[$value].ord => $value }, |(0 .. ^@base64-chars.elems -1).flat).hash; # XXX

    has %!message;

    method new(*%args) {
        return self.bless(:message(%args));
    }

    submethod BUILD(:%!message) {}

    method gist {
        return %!message.gist();
    }

    method write($h) {
        my $buf = to-json(%!message).encode(:encoding<UTF-8>);

        my $length = self!encoded-length($buf.bytes);
        $h.write($length ~ $buf);
    }

    method read($h) {
        my $length = $h.read(4);
           $length = self!decoded-length($length);

        my $body   = $h.read($length).decode(:encoding<UTF-8>);
           $body   = from-json($body);

        my $result = self.bless(:message(%$body));
        return $result;
    }

    method hash {
        return %!message;
    }

    method !encoded-length(Int $length is copy) returns utf8 {
        my @chars;

        for ( 1 .. 4 ) {
            my $value = $length +& 0x3f; # XXX
            @chars.unshift(@base64-chars[$value]);
            $length +>= 6;
        }

        return @chars.join('').encode(:encoding<UTF-8>);
    }

    method !decoded-length(utf8 $length) {
        my $num = 0;

        loop (my $i = 0; $i < $length.elems; $i++) {
            my $value = %base64-mapping{$length[$i]};
            $num +<= 6;
            $num +|= $value;
        }

        return $num;
    }
}
