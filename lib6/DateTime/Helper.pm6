role DateTime::Helper {
    my %seconds-per-unit =
        :second(1),
        :minute(60),
        :hour(60 * 60),
        :day(60 * 60 * 24), # XXX doesn't handle leap second
        :week(60 * 60 * 24 * 7);

    method add(*%amounts) {
        my $total = 0;

        for %amounts.pairs -> $pair {
            # XXX can we do this in the block signature?
            my $unit   = $pair.key;
            my $amount = $pair.value;

            unless %seconds-per-unit.exists($unit) {
                die "Invalid unit '$unit'";
            }

            $total += $amount * %seconds-per-unit{$unit};
        }

        return DateTime.new(self.posix + $total, :timezone(self.timezone));
    }

    method subtract(*%amounts) {
        for %amounts.keys -> $k {
            %amounts{$k} *= -1;
        }

        return self.add(|%amounts);
    }
}
