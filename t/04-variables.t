use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

#############################################################################
# Check if variables can be set correctly and are used in calculations
#############################################################################

subtest 'variables tests' => sub {
	for my $case (
		['o+#va#vb', qr/5$/, a => 2, b => 3],
		['o+#vaa#o+#vbb#o+#vcc#o+#vdd#o+#vee#vff', qr/23\.1/, aa => 1.1, bb => 2.2, cc => 3.3, dd => 4.4, ee => 5.5, ff => 6.6],
	) {
		my ($to_import, $regex, %variables) = @$case;
		my $result = run_good('-i', $to_import, map { ('-v', $_, $variables{$_}) } keys %variables);
		like $result, qr/^$regex/, "calculation $to_import with variables result ok";
	}
};

done_testing;
