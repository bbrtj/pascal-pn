use strict;
use warnings;
use Test::More;

use lib 't/lib';
use CLIHelper;

############################################################################
# Check whether importing and immediately exporting a string yields the same
# string back. These doesn't need to make sense, as the program is not
# validating them at this stage
############################################################################

subtest 'valid strings' => sub {
	for my $case (
		'-1',
		'0',
		'0.1',
		'1.001250142E-299',
		['0E0', '0'],
		['2.9866061145576161E+019', '2.98660611455762E19'],
		['37.333333333333333333333333333333333333333333333333333333333333333333333333333', '37.3333333333333'],
		'vvariable',
		'vo',
		'o**#vo#vo',
		'o+#2#2',
		'o+#2.01#2.001',
		'o*#va#vb#o-#3',
	) {
		my $imported;
		my $exported;

		if (ref $case eq 'ARRAY') {
			($imported, $exported) = @{$case};
		}
		else {
			($imported, $exported) = ($case) x 2;
		}

		is run_good('-i', $imported, '-e'), $exported, "$imported export/import ok";
	}
};

subtest 'invalid strings' => sub {
	for my $case (
		'.',
		'0.',
		'.0',
		'0,0',
		'0.0E',
		'E1',
		'1E-',
		'1.E',
		'1.0E+',
		'1.0E0.1',
		'notavar',
		'5.315notanumber',
		'5.315 notanumber',
		'notanumber 5.315',
		'5.315 + 11',
		'+#5#5',
		'5##5',
	) {
		note run_bad('-i', $case, '-e');
	}
};

done_testing;

