role Hexe::Plugin::Echo {
    method process-message($msg) {
        return unless $msg.type eq 'chat';

        my $reply   = $msg.make-reply;
        $reply.body = $msg.body;
        $.connection.send($reply);
    }
}
