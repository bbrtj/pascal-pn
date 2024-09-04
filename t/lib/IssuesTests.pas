unit IssuesTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, PNBase, SysUtils;

type
	TIssuesSuite = class(TTAPSuite)
	private
		FCalc: TPN;

	public
		constructor Create(); override;

		procedure Setup(); override;
		procedure TearDown(); override;

		procedure GithubIssue1Test();
		procedure GithubIssue2Test();
		procedure GithubIssue3Test();
	end;

implementation

const
	cSmallPrecision = 1E-8;

constructor TIssuesSuite.Create();
begin
	inherited;

	Scenario(@self.GithubIssue1Test, 'Error from github#1 should be fixed');
	Scenario(@self.GithubIssue2Test, 'Error from github#2 should be fixed');
	Scenario(@self.GithubIssue3Test, 'Error from github#3 should be fixed');
end;

procedure TIssuesSuite.Setup();
begin
	self.FCalc := TPN.Create;
end;

procedure TIssuesSuite.TearDown();
begin
	self.FCalc.Free;
end;

procedure TIssuesSuite.GithubIssue1Test();
begin
	FCalc.ParseString('fact(10)/100');

	TestWithin(FCalc.GetResult, 36288, cSmallPrecision, 'result ok');
end;

procedure TIssuesSuite.GithubIssue2Test();
begin
	FCalc.ParseString('fact(2) + fact(2) + fact(2)');

	TestWithin(FCalc.GetResult, 6, cSmallPrecision, 'result ok');
end;

procedure TIssuesSuite.GithubIssue3Test();
begin
	try
		FCalc.ParseString('15 lol');
		TestFail('Parsing should result in an error');
	except
		on E: EParsingFailed do TestPass('Got expected error with message: ' + E.Message);
		on E: Exception do TestFail('Got unexpected error with message: ' + E.Message);
	end;
end;

end.

