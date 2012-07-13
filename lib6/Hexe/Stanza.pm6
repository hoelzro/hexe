use Hexe::JID;

my role StanzaLike {
    # XXX private method in a role
    method find-node(%node, *%search-params) returns Hash {
        my $all-matching = True;

        for %search-params.pairs -> $pair {
            my $node-value = %node{$pair.key};

            unless $pair.value eq $node-value {
                $all-matching = False;
                last;
            }
        }

        if $all-matching {
            return %node;
        }

        for %node<_children>.list -> $child {
            my $result = self.find-node($child, |%search-params);
            if $result.defined {
                return $result;
            }
        }

        return Hash;
    }
}

# XXX build junctions with a list?
subset Hexe::Stanza::Presence::Type of Str where 'available'|'error'|'subscribe'|'subscribed'|'unavailable'|'unsubscribe'|'unsubscribed';
subset Hexe::Stanza::Presence::Availability of Str where 'away'|'chat'|'dnd'|'xa';
subset Hexe::Stanza::Presence::Priority of Int where -128 .. 127;

class Hexe::Stanza::Presence does StanzaLike {
    has Hexe::Stanza::Presence::Type $!type;
    has Hexe::JID $!from;
    has Hexe::Stanza::Presence::Availability $!availability;
    has Str $!status;
    has Hexe::Stanza::Presence::Priority $!priority;

    method new(%obj) {
        my %params = :type(%obj<type>), :from(%obj<from>);

        unless %params<type>.defined {
            %params<type> = 'available';
        }

        %params<availability> = self.find-node(%obj, :_tag<show>)<_text>         || 'available';
        %params<status>       = self.find-node(%obj, :_tag<status>)<_text>       || Str;
        %params<priority>     = self.find-node(%obj, :_tag<priority>)<_text>.Int || 0;

        return self.bless(*, |%params);
    }

    submethod BUILD(:$!type, Str :$from, :$!availability, :$!status, :$!priority) {
        # XXX can we coerce $from in the signature?
        $!from = Hexe::JID.from-string($from);
    }

    method gist {
        # XXX make this smarter
        if self.defined {
            my @pieces = ("type='$!type'", "from='$!from'");

            if $!availability.defined {
                @pieces.push("availability='$!availability'");
            }

            if $!status.defined {
                @pieces.push("status='$!status'");
            }

            if $!priority.defined {
                @pieces.push("priority=$!priority");
            }

            return 'presence: ' ~ @pieces.join(', ');
        } else {
            nextsame;
        }
    }
}

subset Hexe::Stanza::Message::Type of Str where 'chat'|'error'|'groupchat'|'headline'|'normal';

my regex delay-regex {
    $<year>=(\d ** 4)
    '-'
    $<month>=(\d ** 2)
    '-'
    $<day>=(\d ** 2)
    T
    $<hour>=(\d ** 2)
    ':'
    $<minute>=(\d ** 2)
    ':'
    $<second>=(\d ** 2)
    Z
}

class Hexe::Stanza::Message does StanzaLike {
    has Hexe::Stanza::Message::Type $.type is rw;
    has Hexe::JID $.from is rw;
    has Hexe::JID $.to is rw;
    has DateTime $.delay;
    has Str $.body is rw;

    # the difference between the two new invocations
    # is subtle; one allows .new(:from(...), ...),
    # the other allows .new(%xml-node)
    multi method new(*%params) {
        return self.bless(*, |%params);
    }

    multi method new(%obj) {
        my %params = :type(%obj<type>), :from(%obj<from>), :to(%obj<to>);

        %params<body> = self.find-node(%obj, :_tag<body>)<_text>;
        my $delay     = self.find-node(%obj, :_tag<delay>)<stamp>;

        if $delay.defined {
            if $delay ~~ /^ <delay-regex> $/ -> $match {
                my $delay-part = $match<delay-regex>;
                my @keys       = qw<year month day hour minute second>;
                my %params;

                for @keys -> $k {
                    my $value   = $delay-part{$k}.Int;
                    %params{$k} = $value;
                }

                $delay = DateTime.new(|%params);
            }
        } else {
            $delay = DateTime;
        }
        %params<delay> = $delay;

        return self.bless(*, |%params);
    }

    submethod BUILD(:$!type, :$from, :$to, Str :$!body, DateTime :$!delay) {
        if $from ~~ Str {
            $!from = Hexe::JID.from-string($from);
        } else {
            $!from = $from;
        }

        if $to ~~ Str {
            $!to = Hexe::JID.from-string($to);
        } else {
            $!to = $to;
        }
    }

    method gist {
        if self.defined {
            return "message: type='$!type', from='$!from', to='$!to', body = '$!body'";
        } else {
            nextsame;
        }
    }

    method is-delayed {
        return $!delay.defined;
    }

    method make-reply {
        my $from = $.to;
        my $to   = $.from;

        if $.type eq 'groupchat' {
            $to          = $to.clone;
            $to.resource = Str;
        }
        return Hexe::Stanza::Message.new(:type($.type), :to($to), :from($from));
    }
}

class Hexe::Stanza {
    method create($obj) {
        given $obj<_tag> {
            when 'presence' {
                return Hexe::Stanza::Presence.new($obj);
            }
            when 'message' {
                return Hexe::Stanza::Message.new($obj);
            }
            default {
                return Failure("Unknown tag '$obj<_tag>'");
            }
        }
    }
}
