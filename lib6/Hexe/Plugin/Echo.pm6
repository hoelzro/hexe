role Hexe::Plugin::Echo {
    method process-message($msg) {
        my $me = self.nickname;

        if $msg.type eq 'chat' {
            my $reply   = $msg.make-reply;
            $reply.body = $msg.body;
            $.connection.send($reply);
        } elsif $msg.type eq 'groupchat' {
            my $match = $msg.body ~~ /^ <$me> <[:,]>\s*(.*)/;
            return unless $match;

            my $sender  = $msg.from.resource;
            my $reply   = $msg.make-reply;
            $reply.body = "$sender: $match[0]";
            $.connection.send($reply);
        }
    }
}
