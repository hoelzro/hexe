role Hexe::Plugin::Echo {
    method process-message($msg) {
        my $me = self.nickname;

        if $msg.type eq 'chat' {
            my $reply   = $msg.make-reply;
            $reply.body = $msg.body;
            $.connection.send($reply);
        } elsif $msg.type eq 'groupchat' {
            my $body = $msg.body;
            return unless $body ~~ /^ "$me" <[:,]>/;
            my $sender  = $msg.from.resource;
            my $reply   = $msg.make-reply;
            $reply.body = "$sender: {$msg.body}";
            $.connection.send($reply);
        }
    }
}
