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
		['2 + -3', 'o+#2#p-#3'],
		['2 + 3 * 4', 'o+#2#o*#3#4'],
		['2 + -3 * 4', 'o+#2#o*#p-#3#4'],
		['2 * 3 + 4', 'o+#o*#2#3#4'],
		['2 * -3 + 4', 'o+#o*#2#p-#3#4'],
		['2 + 3 * var', 'o+#2#o*#3#vvar'],
		['a + b * c', 'o+#va#o*#vb#vc'],
		['2 - 3 - 4', 'o-#o-#2#3#4'],
		['2 + 3 ^ 4 * 5 - 6', 'o-#o+#2#o*#o^#3#4#5#6'],
	) {
		my $result = run_good('-p', $case->[0], '-e');
		is $result, $case->[1], "parsing $case->[0] result ok";
	}
};

subtest 'nested contexts' => sub {
	for my $case (
		['-(-2 + 3)', 'p-#o+#p-#2#3'],
		['-ln 5 + 3', 'p-#pln#o+#5#3'],
		['-log 2, log 2, 16', 'p-#plog#o,#2#plog#o,#2#16'],
		['log 2 + 3, 4 + 5', 'plog#o,#o+#2#3#o+#4#5'],
		['(2 + 3) * 4', 'o*#o+#2#3#4'],
		['(2 + 3) * (4 + 5) + (6 - 7)', 'o+#o*#o+#2#3#o+#4#5#o-#6#7'],
		['(2 + 3) + 4', 'o+#o+#2#3#4'],
		['((1 + 2) * 3) ^ 4', 'o^#o*#o+#1#2#3#4'],
		['1 + (2 * (3 ^ 4))', 'o+#1#o*#2#o^#3#4'],
		['5 + (1 + (2 * (3 ^ 4)))', 'o+#5#o+#1#o*#2#o^#3#4'],
		['5 + (1 + (2 * (3 ^ a * ab)))', 'o+#5#o+#1#o*#2#o*#o^#3#va#vab'],
	) {
		my $result = run_good('-p', $case->[0], '-e');
		is $result, $case->[1], "parsing $case->[0] result ok";
	}
};

subtest 'invalid examples' => sub {
	for my $case (
		'21 + []', # not a valid variable name
		'21 + aaaa[', # only partially valid variable name
		'this - is * (test', # unmatched braces
		'this - is * )test', # unmatched braces
		'2 2+2', # unexpected 2
		'2+2 2', # unexpected 2
	) {
		run_bad('-p', $case, '-e');
	}
};

done_testing;

