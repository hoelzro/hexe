module Dumper;

proto dump($, Int $ = 0) is export {*};

multi dump(Str:D $s, Int $ = 0) {
    return '"' ~ $s ~ '"';
}

multi dump(Pair:D $p, Int $indent = 0) {
    return '  ' x $indent ~ dump($p.key, $indent + 1) ~ ' => ' ~ dump($p.value, $indent + 1);
}

multi dump(Array:D $a, Int $indent = 0) {
    return '[]' if !$a;

    my @parts;

    @parts.push("[\n");
    for $a.list -> $elem {
        @parts.push(dump($elem, $indent + 1));
        @parts.push(",\n");
    }
    @parts.push('  ' x $indent ~ ']');

    return @parts.join('');
}

multi dump(Hash:D $h, Int $indent = 0) {
    my @parts;

    @parts.push('  ' x $indent ~ "\{\n");

    for $h.pairs -> $pair {
        @parts.push(dump($pair, $indent + 1));
        @parts.push(",\n");
    }

    @parts.push('  ' x $indent ~ '}');

    return @parts.join('');
}

multi dump(Any:U $, Int $ = 0) {
    return 'undefined'
}

multi dump(Any:D $obj, Int $ = 0) {
    die "Cannot dump objects of type {$obj.WHAT.gist}";
}
