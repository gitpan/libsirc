# $Id: Autoop.pm,v 1.2 1998-11-27 11:57:34-05 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;

package Sirc::Autoop;

use Exporter		();
use Sirc::Chantrack	qw(%Chan_op %Chan_user %Chan_voice);
use Sirc::Util		qw(addcmd add_hook addhook docommand
			    have_ops have_ops_q ieq optional_channel
			    settable_boolean settable_int tell_question
			    timer userhost xgetarg xtell);

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK
	    @Autoop $Autoop $Autoop_delay $Debug $Verbose);

$VERSION  = do{my@r=q$Revision: 1.2 $=~/\d+/g;sprintf '%d.'.'%03d'x$#r,@r};
$VERSION .= '-l' if q$Locker:  $ =~ /: \S/;

@ISA		= qw(Exporter);
@EXPORT		= qw(@Autoop);
@EXPORT_OK	= qw($Autoop $Autoop_delay $Debug $Verbose);

# @Autoop is a list of array references.  The first element of each
# array is a pattern to match against the channel, the second is a
# pattern to match agains the nick!user@host.  The optional third is
# either 'o' or 'v' (defaulting to 'o') to tell which mode to give.
#
# There's no user-level interface for adding data to this (yet).
@Autoop		= ();

# These variables are tied to /set options, though $Autoop_delay can
# only be set to an integer now.  (It's default definition is meant to
# cut down on redundant mode changes when multiple people use this
# code.)
$Autoop		= 1;				# no autoops done if false
$Autoop_delay	= sub { 3 + 2 * int rand 4 };	# secs before trying to autoop
$Debug		= 0;
$Verbose	= 0;

settable_boolean 'autoop', \$Autoop;
settable_boolean 'autoop_debug', \$Debug;
settable_boolean 'autoop_verbose', \$Verbose;
settable_int 'autoop_delay', \$Autoop_delay, sub { $_[1] >= 0 };

sub debug {
    xtell 'autoop debug ' . join '', @_
	if $Debug;
}

sub verbose {
    xtell join '', @_
	if $Verbose || $Debug;
}

sub autoop_match {
    my ($channel, $nuh) = @_;

    debug "autoop_match @_";
    for (@Autoop) {
	my ($channel_pat, $nuh_pat, $type) = @$_;

	$type = 'o' if !defined $type;
	if ($type ne 'o' && $type ne 'v') {
	    tell_question "Invalid autoop type `$type'"
    	    	    	    . " for /$channel_pat/ /$nuh_pat/";
	    next;
	}

	my $one = $channel =~ /$channel_pat/i;
	my $two = $nuh =~ /$nuh_pat/i;
	debug "channel/user $one/$two on $channel_pat/$nuh_pat";
	if ($one && $two) {
	    return $type;
	}
    }
    return 0;
}

sub autoop_try {
    my ($this_channel, $this_nick, $this_userhost, $this_delay) = @_;

    debug "autoop_try @_";
    $Autoop or return;
    have_ops $this_channel or return;
    return if ieq $this_nick, $::nick;

    my $type = autoop_match $this_channel, "$this_nick!$this_userhost";
    return unless $type;

    verbose "Queueing +$type for $this_nick on $this_channel in $this_delay"
	if $this_delay > 0;
    timer $this_delay, sub {
	# Don't +v or +o for ops.
	if ($Chan_op{$this_channel}{$this_nick}) {
	    debug "autop_try skip $this_channel/$this_nick opped";
	}
	# Don't +v people who got it already.
	elsif ($type eq 'v' && $Chan_voice{$this_channel}{$this_nick}) {
	    debug "autop_try skip $this_channel/$this_nick voiced";
	}
	# Don't +v if we're not moderated.
	elsif ($type eq 'v' && $::mode{lc $this_channel} !~ /m/) {
	    debug "autop_try skip $this_channel/$this_nick not +m";
	}
	elsif (!$Chan_user{$this_channel}{$this_nick}) {
	    debug "autoop_try skip $this_channel/$this_nick gone";
	}
	else {
	    debug "autoop_try op $this_channel/$this_nick";
	    docommand "mode $this_channel +$type $this_nick\n";
	}
    };
}

sub main::hook_autoop_join {
    my $channel = shift;
    my @arg = ($channel, $::who, "$::user\@$::host");
    autoop_try @arg, ref($Autoop_delay) eq 'CODE'
			? &$Autoop_delay(@arg)
			: $Autoop_delay
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
