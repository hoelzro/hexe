use DBIish;

role Hexe::Plugin::Storage {
    has $.storage;

    method init {
        mkdir(%*ENV<HOME> ~ '/.hexe');
        my $db_path = %*ENV<HOME> ~ '/.hexe/data.db';

        $.storage = DBIish.connect('SQLite', :database($db_path));
    }
}
