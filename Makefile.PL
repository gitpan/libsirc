# $Id: Makefile.PL,v 1.2 1998-10-22 23:14:24-04 roderick Exp $
#
# Copyright (c) 1997 Roderick Schertler.  All rights reserved.  This
# program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use ExtUtils::MakeMaker;

WriteMakefile(
    DISTNAME		=> 'libsirc',
    NAME		=> 'Sirc',
    VERSION		=> '0.02',
    dist		=> {
    	COMPRESS 	=> 'gzip --best',
    	DIST_CP		=> 'ln',
    	PREOP		=> '$(MAKE) ci',
    	SUFFIX		=> 'gz',
    },
    test		=> { TESTS => 'test.t' },
);
