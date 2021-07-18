use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check whether the CLI application works at all by printing its help message
#############################################################################

subtest 'show help' => sub {
	like run_good('--help'), qr/Usage:/, 'help printed ok';
};

done_testing;
