#!perl -w
use strict;

# $Id: test.t,v 1.1 1997-12-16 18:58:24-05 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

BEGIN {
    $| = 1;
    print "1..1\n";
}

use Sirc::Chantrack ();
use Sirc::Util ();

sub test {
    my ($n, $result, @info) = @_;
    if ($result) {
    	print "ok $n\n";
    }
    else {
    	print "not ok $n\n";
	print "# ", @info, "\n" if @info;
    }
}

test 1, 1;
