use Hexe::JID;

my role StanzaLike {
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

        %params<availability> = self.find-node(%obj, :_tag<show>)<_text>         || Hexe::Stanza::Presence::Availability;
        %params<status>       = self.find-node(%obj, :_tag<status>)<_text>       || Str;
        %params<priority>     = self.find-node(%obj, :_tag<priority>)<_text>.Int || Hexe::Stanza::Presence::Priority;

        return self.bless(*, |%params);
    }

    submethod BUILD(:$!type, Str :$from, :$!availability, :$!status, :$!priority) {
        $!from = Hexe::JID.from-string($from);
    }

    method gist {
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
    }
}

subset Hexe::Stanza::Message::Type of Str where 'chat'|'error'|'groupchat'|'headline'|'normal';

class Hexe::Stanza::Message does StanzaLike {
    has Hexe::Stanza::Message::Type $!type;
    has Hexe::JID $!from;
    has Hexe::JID $!to;
    has Str $!body;

    method new(%obj) {
        my %params = :type(%obj<type>), :from(%obj<from>), :to(%obj<to>);

        %params<body> = self.find-node(%obj, :_tag<body>)<_text>;

        return self.bless(*, |%params);
    }

    submethod BUILD(:$!type, Str :$from, Str :$to, Str :$!body) {
        $!from = Hexe::JID.from-string($from);
        $!to   = Hexe::JID.from-string($to);
    }

    method gist {
        return "message: type='$!type', from='$!from', to='$!to', body = '$!body'";
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
