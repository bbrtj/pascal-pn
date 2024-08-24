use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check if calculations from imported strings yield the right results
#############################################################################

subtest 'regular calculations' => sub {
	for my $case (
		['6.66', qr/6\.66(0+.)?$/], # possible floating point precision artifact
		['o/#20#3', qr/6\.6+./], # insufficient floating point precision
		['o*#3#o/#20#3', qr/20$/], # back into an integer
		['o*#-0.01#100', qr/-1$/], # positive * negative
		['o^#-5#2', qr/25$/], # negative ^ even
		['o-#-0.1#-0.1', qr/0$/], # negative - negative
	) {
		my $result = run_good('-i', $case->[0]);
		like $result, qr/^$case->[1]/, "calculation $case->[0] result ok";
	}
};

subtest 'tricky calculations' => sub {
	for my $case (
		['o+#0.3#o+#0.3#o+#0.3#o+#0.3#o+#0.3#o+#0.3#o+#0.3#o+#0.3#0.3', qr/(2\.69+.|2\.7)$/], # many operations
		['o+#0.000005#0.000007', qr/0\.000012$/], # small numbers
		['o+#200000000000#1', qr/200000000001$/], # large numbers
		['o+#200000000000.1#1.1', qr/200000000001\.2(0+.)?$/], # large numbers
		['o+#200000000000.1#1.1', qr/200000000001\.2(0+.)?$/], # large numbers with decimal places
		['o+#0.0123456789#0', qr/0\.0123456789$/], # large numbers with decimal places
	) {
		my $result = run_good('-i', $case->[0]);
		like $result, qr/^$case->[1]/, "calculation $case->[0] result ok";
	}
};

done_testing;

