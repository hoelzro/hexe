use Hexe::Plugin::Storage;

role Hexe::Plugin::Karma {
    also does Hexe::Plugin::Storage;

    # XXX also respond to karma command
    method process-message($msg) {
        my $match = $msg ~~ / (.*) '++'/;

        return unless $match;

        my $storage  = self.storage;
        my $username = $match[0].Str;
    }
}
