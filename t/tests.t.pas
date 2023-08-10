program PNUnitTest;

uses TAPSuite,
	BaseTests, CalcTests, ParseErrorTests;

begin
	Suite(TBaseSuite);
	Suite(TCalculationsSuite);
	Suite(TParseErrorSuite);

	RunAllSuites;
end.

