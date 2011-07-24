#!/usr/bin/perl

use strict;
use warnings;

use LWP;

my $ua = LWP::UserAgent->new();

my $content = $ua->get("https://repository.apache.org/content/groups/snapshots/org/apache/openejb/apache-tomee/4.0.0-SNAPSHOT/")->content;

$content = join(" ", split("[ \r\n]+", $content));
$content =~ s/(<tr>)/\n$1/g;
$content =~ s,(</tr>),$1\n,g;

foreach my $line (split("\n", $content)) {
    next if $line =~ /\.(sha1|md5|jar|pom|xml)|Parent/;
    print $line . "\n";
}
