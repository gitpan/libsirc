# $Id: Autoop.pm,v 1.1 1998-10-22 23:09:26-04 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;

package Sirc::Autoop;

use Exporter		();
use Sirc::Chantrack	qw(%Chan_op %Chan_user);
use Sirc::Util		qw(addcmd add_hook addhook docommand
			    have_ops have_ops_q ieq optional_channel
			    settable_boolean settable_int timer userhost
			    xgetarg xtell);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK
	    @Autoop $Autoop $Autoop_delay $Debug);

$VERSION  = do{my@r=q$Revision: 1.1 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

@ISA		= qw(Exporter);
@EXPORT		= qw(@Autoop);
@EXPORT_OK	= qw($Autoop $Autoop_delay $Debug);

# @Autoop is a list of array references.  The first element of each
# array is a pattern to match against the channel, the second is a
# pattern to match agains the nick!user@host.  There's no user-level
# interface for adding data to this (yet).
@Autoop		= ();

# These variables are tied to /set options.
$Autoop		= 1;	# no autoops done if false
$Autoop_delay	= 25;	# pause before trying to autoop
$Debug		= 0;

settable_boolean 'autoop', \$Autoop;
settable_boolean 'autoop_debug', \$Debug;
settable_int 'autoop_delay', \$Autoop_delay, sub { $_[1] >= 0 };

sub debug {
    xtell 'autoop debug ' . join '', @_
	if $Debug;
}

sub autoop_match {
    my ($channel, $nuh) = @_;

    debug "autoop_match @_";
    for (@Autoop) {
	my ($channel_pat, $nuh_pat) = @$_;
	my $one = $channel =~ /$channel_pat/i;
	my $two = $nuh =~ /$nuh_pat/i;
	debug "channel/user $one/$two on $channel_pat/$nuh_pat";
	if ($one && $two) {
	    return 1;
	}
    }
    return 0;
}

sub autoop_try {
    my ($this_channel, $this_nick, $this_userhost, $this_delay) = @_;

    debug "autoop_try @_";
    $Autoop && have_ops $this_channel or return;
    return unless autoop_match $this_channel, "$this_nick!$this_userhost";
    xtell "Queueing op for $this_nick on $this_channel in $this_delay"
	if $this_delay > 0;
    timer $this_delay, sub {
	if ($Chan_op{$this_channel}{$this_nick}) {
	    debug "autop_try skip $this_channel/$this_nick opped";
	}
	elsif (!$Chan_user{$this_channel}{$this_nick}) {
	    debug "autoop_try skip $this_channel/$this_nick gone";
	}
	else {
	    debug "autoop_try op $this_channel/$this_nick";
	    docommand "mode $this_channel +o $this_nick\n";
	}
    };
}

sub main::hook_autoop_join {
    my $channel = shift;
    autoop_try $channel, $::who, "$::user\@$::host", $Autoop_delay
	if have_ops_q $channel;
}
addhook 'join', 'autoop_join';

# /autoop [channel]
sub main::cmd_autoop {
    debug "cmd_autoop $::args";
    optional_channel or return;
    my $c = lc xgetarg;
    have_ops $c or return;
    $Autoop or return;
    userhost [keys %{ $Chan_user{$c} }], sub {
	autoop_try $c, $::who, "$::user\@$::host", 0;
    };
}
addcmd 'autoop';

# Try an /autoop after receiving ops.
add_hook '+op', sub {
    my ($c, $n) = @_;

    timer 10, sub { main::cmd_autoop $c } if ieq $n, $::nick;
};
