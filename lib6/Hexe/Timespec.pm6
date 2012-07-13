use DateTime::Helper;

class Hexe::Timespec {
    my %day-specs =
        :Monday(1),
        :Tuesday(2),
        :Wednesday(3),
        :Thursday(4),
        :Friday(5),
        :Saturday(6),
        :Sunday(7);

    %day-specs<Weekday> = any(%day-specs<Monday Tuesday Wednesday Thursday Friday>);
    %day-specs<Day>     = any(%day-specs<Monday Tuesday Wednesday Thursday Friday Saturday Sunday>);

    has $!day-spec  = %day-specs<Day>;
    has $!time-spec = 0;

    method every(Str $day-spec where %day-specs) {
        $!day-spec = %day-specs{$day-spec};
        return self;
    }

    method at(Str $time-spec) {
        if $time-spec ~~ /^ $<hour>=(\d\d) ':' $<minute>=(\d\d) $/ -> $match {
            my $hour   = $match<hour>.Int;
            my $minute = $match<minute>.Int;

            unless 0 <= $hour <= 23 {
                die "Invalid hour: $hour";
            }

            unless 0 <= $minute <= 59 {
                die "Invalid minute: $minute";
            }

            $!time-spec = $hour * 60 + $minute;
        } else {
            die "Invalid time specification '$time-spec'";
        }

        return self;
    }

    method next-occurrence {
        my $now  = DateTime.now;
        my $next = $now;

        while True {
            while $next.day-of-week !~~ $!day-spec {
                $next does DateTime::Helper;
                $next = $next.add(:day(1));
            }
            $next = DateTime.new(
                :year($next.year),
                :month($next.month),
                :day($next.day),
                :hour(($!time-spec / 60).floor),
                :minute($!time-spec % 60),
                :second(0),
                :timezone($now.timezone),
            );

            # XXX it would be nice to be able to do $next <= $now
            if $next.posix <= $now.posix {
                $next does DateTime::Helper;
                $next = $next.add(:day(1));
            } else {
                last;
            }
        }

        return $next;
    }
}
