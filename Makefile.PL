# $Id: Makefile.PL,v 1.6 1999-01-08 17:47:32-05 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(
    DISTNAME		=> 'libsirc',
    NAME		=> 'Sirc',
    VERSION_FROM	=> 'Sirc/Util.pm',
    dist		=> {
    	COMPRESS 	=> 'gzip --best',
    	DIST_CP		=> 'ln',
    	PREOP		=> '$(MAKE) ci',
    	SUFFIX		=> 'gz',
    },
    test		=> { TESTS => 'test.t' },
);
