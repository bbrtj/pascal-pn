program Tests;

uses TAPSuite,
	BaseTests, CalcTests, ParseErrorTests, IssuesTests;

begin
	Suite(TBaseSuite);
	Suite(TCalculationsSuite);
	Suite(TParseErrorSuite);
	Suite(TIssuesSuite);

	RunAllSuites;
end.

