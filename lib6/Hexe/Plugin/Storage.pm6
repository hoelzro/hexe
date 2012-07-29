use DBIish;

role Hexe::Plugin::Storage {
    has $.storage;

    method storage {
        unless $!storage.defined {
            my $config-path = %*ENV<HOME> ~ '/.hexe';
            unless $config-path.IO ~~ :d {
                mkdir($config-path);
            }
            my $db_path = "$config-path/data.db";

            $!storage = DBIish.connect('SQLite', :database($db_path));
        }

        return $!storage;
    }
}
