use Hexe::Plugin::Storage;

role Hexe::Plugin::Karma {
    also does Hexe::Plugin::Storage;

    # XXX karma specific to a room
    # XXX aliases for usernames
    method init {
        $.storage.do(q{
CREATE TABLE IF NOT EXISTS karma (
    username TEXT    NOT NULL,
    karma    INTEGER NOT NULL DEFAULT 1
);
        });
    }

    # XXX also respond to karma command
    method process-message($msg) {
        my $match = $msg.body ~~ / $<username>=(.*) '++'/;

        return unless $match;

        my $storage  = self.storage;
        my $username = $match<username>.Str;

        my $sth = $storage.prepare('UPDATE karma SET karma = karma + 1 WHERE username = ?');

        my $n_changed = $sth.execute($username);

        if $n_changed == 0 {
            $sth = $storage.prepare('INSERT INTO karma VALUES (?, ?)');

            $sth.execute($username, 1);
        }
    }
}
