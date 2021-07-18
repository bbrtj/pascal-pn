package CLIHelper;

use strict;
use warnings;
use Test::More;
use Exporter qw(import);

our @EXPORT = qw(run);

use constant PROGRAM_PATH => 'build/cli';

sub run
{
	my (@args) = @_;

	die 'Program not yet compiled or not executable'
		unless -x PROGRAM_PATH;

	# capture stderr as well
	push @args, '2>&1';
	my $cmd = join ' ', PROGRAM_PATH, @args;

	my $data = qx($cmd);

	is $?, 0, 'error code ok';
	return $data;
}

1;
