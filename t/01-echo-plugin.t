# vim:ft=perl6

use v6;
use lib 't/lib';

use Test;
use Test::HexePlugin;

use Hexe::Plugin::Echo;

plan 3;

my $tester = Test::HexePlugin.new(
    :bot-nick<hexe>,                  # optional; defaults to hexe
    :my-nick<tester>,                 # optional; defaults to tester
    :send-prefix('> '),               # optional; defaults to '> '
    :recv-prefix('< '),               # optional; defaults to '< '
    :plugins([ Hexe::Plugin::Echo ]), # required
);

$tester.check-responses([
    '> hello',
    '< hello',
]);

$tester.check-group-responses([
    '> hello',
]);

$tester.check-group-responses([
    '> hexe: hello',
    '< tester: hello',
]);
