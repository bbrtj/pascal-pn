use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check whether parsing regular notation to Polish notation works correctly
#############################################################################

subtest 'single context' => sub {
	for my $case (
		['2 + 3', 'o+#2#3'],
		['2 + 3 * 4', 'o+#2#o*#3#4'],
		['2 + 3 * var', 'o+#2#o*#3#vvar'],
		['a + b * c', 'o+#va#o*#vb#vc'],
	) {
		my $result = run_good('-p', $case->[0], '-e');
		is $result, $case->[1], "parsing $case->[0] result ok";
	}
};

subtest 'nested contexts' => sub {
	for my $case (
		['(2 + 3) * 4', 'o*#o+#2#3#4'],
	) {
		my $result = run_good('-p', $case->[0], '-e');
		is $result, $case->[1], "parsing $case->[0] result ok";
	}
};

done_testing;
