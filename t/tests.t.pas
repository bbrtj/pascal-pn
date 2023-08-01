program PNUnitTest;

uses TAPSuite,
	BaseTests, CalcTests;

begin
	Suite(TBaseSuite);
	Suite(TCalculationsSuite);

	RunAllSuites;
end.

