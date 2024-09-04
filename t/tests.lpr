program Tests;

uses TAPSuite,
	BaseTests, CalcTests, ParseErrorTests, CalcErrorTests, IssuesTests;

begin
	Suite(TBaseSuite);
	Suite(TCalculationsSuite);
	Suite(TParseErrorSuite);
	Suite(TCalcErrorSuite);
	Suite(TIssuesSuite);

	RunAllSuites;
end.

