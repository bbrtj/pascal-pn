use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

############################################################################
# Check whether importing and immediately exporting a string yields the same
# string back
############################################################################

for my $case (
	'++#2#2',
	'+*#$a#$b#+-#3',
) {
	is run('-i', $case, '-e'), $case, "$case export/import ok";
}

done_testing;
