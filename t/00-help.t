use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check whether the CLI application works at all by printing its help message
#############################################################################

like run('--help'), qr/Usage:/, 'help printed ok';

done_testing;
