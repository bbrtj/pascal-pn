use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check if operators are defined and seem to do the right thing
#############################################################################

subtest 'check operators' => sub {
	for my $case (
		['p-#2', qr/-2$/],
		['o+#2.5#3.5', qr/6$/],
		['o-#2.5#3.5', qr/-1$/],
		['o*#2.5#3.5', qr/8\.75$/],
		['o/#2.5#3.5', qr/0\.71428/],
		['o%#2.5#3.5', qr/2\.5$/],
	) {
		my $result = run_good('-i', $case->[0]);
		like $result, qr/^$case->[1]/, "operator in $case->[0] ok";
	}
};

done_testing;

