my regex node-part { <-[@]>+ };
my regex domain-part { .+? };
my regex resource-part { <-[/]>+ };
my regex jid-regex { [ <node-part> '@' ]? <domain-part> [ '/' <resource-part> ]? };

class Hexe::JID {
    has Str $.node     is rw;
    has Str $.domain   is rw;
    has Str $.resource is rw;

    method from-string(Str $string) {
        my %attrs;

        if $string ~~ /^ <jid-regex> $/ -> $match {
            my $jid-match = $match{'jid-regex'};

            %attrs<domain>   = $jid-match{'domain-part'}.Str;
            %attrs<node>     = $jid-match{'node-part'}.Str     if $jid-match{'node-part'}.Str.chars     > 0;
            %attrs<resource> = $jid-match{'resource-part'}.Str if $jid-match{'resource-part'}.Str.chars > 0;
        } else {
            die "'$string' does not look like a JID!";
        }

        return self.bless(*, |%attrs);
    }

    submethod BUILD(Str :$!domain!, Str :$!node, Str :$!resource) {}

    method Str {
        return $?CLASS.^name unless self.defined;

        if $!resource.defined {
            return sprintf('%s@%s/%s', $!node, $!domain, $!resource);
        } else {
            if $!node.defined {
                return $!node ~ '@' ~ $!domain;
            } else {
                return $!domain;
            }
        }
    }

    method gist {
        return self.Str();
    }
}
