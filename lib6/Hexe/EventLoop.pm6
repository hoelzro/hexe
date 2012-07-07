use v6;

use MuEvent;

my $instance;

class Hexe::EventLoop {
    method new {
        unless $instance.defined {
            $instance = self.bless(*);
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

    method timer(*%params) {
        if %params.delete('callback') -> $callback {
            %params{'cb'} = $callback;
        }
        unless %params.exists('after') {
            %params{'after'} = 0;
        }
        MuEvent::timer(|%params);
    }

    method stop {
        die 'Hexe::EventLoop';
    }
}
