package CLIHelper;

use strict;
use warnings;
use Test::More;
use Exporter qw(import);

our @EXPORT = qw(run run_good run_bad);

use constant PROGRAM_PATH => 'build/cli';

sub get_cmd
{
	die 'Program not yet compiled or not executable'
		unless -x PROGRAM_PATH;

	return join ' ', PROGRAM_PATH,
		map { / / ? "'$_'" : $_ } @_;
}

sub run
{
	my ($cmd) = @_;

	# capture stderr as well
	$cmd .= ' 2>&1';

	my $data = qx($cmd);

	note $data;
	return $data;
}

sub run_good
{
	my $cmd = get_cmd @_;
	my $res = run $cmd;
	is $?, 0, "error code ok ($cmd)";

	return $res;
}

sub run_bad
{
	my $cmd = get_cmd @_;
	my $res = run $cmd;
	isnt $?, 0, "error code ok ($cmd)";

	return $res;
}

1;
