package OpenEJBSiteDotiacFilter;
use strict;
use warnings;
use Text::Markdown qw( markdown );
use Dotiac::DTL::Value;
use Dotiac::DTL::Filter;

sub import {
    *Dotiac::DTL::Filter::markdown = \&markdown_filter;
}

sub markdown_filter {
    my $value = shift;

    # Use raw value rather than escape (by calling repr() rather than
    # string()) so that we can embed html in our .mdtext documents.
    my $raw  = $value->repr;

    $raw =~ s,\(/\),<IMG class="emoticon" src="http://tomee.staging.apache.org/resources/images/check.png" height="16" width="16" align="absmiddle" alt="" border="0">,g;
    $raw =~ s,\(x\),<IMG class="emoticon" src="http://tomee.apache.org/resources/images/error.png" height="16" width="16" align="absmiddle" alt="" border="0">,g;


    my $start = "{{{{{";
    my $end = "}}}}}";

    $raw =~ s,(^|\n){,$start,g;
    $raw =~ s,(^|\n)},$end,g;

    my $html = markdown($raw);

    $html =~ s,$start([a-z0-9-]+),<div class="$1">,g;
    $html =~ s,$end,</div>,g;

    $html =~ s,<li><p>,<li>,g;
    $html =~ s,</p></li>,</li>,g;


    # Blindly mark return value as safe.
    my $retval = Dotiac::DTL::Value->safe($html);

    return $retval;
}

1;

__END__

=head1 LICENSE

    Licensed to the Apache Software Foundation (ASF) under one or more
    contributor license agreements.  See the NOTICE file distributed with
    this work for additional information regarding copyright ownership.  The
    ASF licenses this file to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance with the
    License.  You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
    License for the specific language governing permissions and limitations
    under the License.

=cut

