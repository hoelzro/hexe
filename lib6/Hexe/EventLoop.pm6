use v6;

use MuEvent;

my $instance;

class Hexe::EventLoop {
    method new {
        unless $instance.defined {
            $instance = self.bless;
        }

        return $instance;
    }

    method go {
        MuEvent::run;

        CATCH {
            when /'Hexe::EventLoop'/ {
                return;
            }

            default {
                $_.rethrow;
            }
        }
    }

    method timer(:$after = 0, :callback($cb), *%params) {
        MuEvent::timer(:$after, :$cb, |%params);
    }

    method io(:$fh, :callback($cb), *%params) {
        MuEvent::socket(:$fh, :$cb, |%params);
    }

    method stop {
        die 'Hexe::EventLoop';
    }
}
