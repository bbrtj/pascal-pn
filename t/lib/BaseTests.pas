unit BaseTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, SysUtils;

type
	TBaseSuite = class(TTAPSuite, ITAPSuiteEssential)
	public
		constructor Create(); override;

		procedure CreateTest();
		procedure ObviousCalcTest();
	end;


implementation

const
	cSmallPrecision = 1E-8;

constructor TBaseSuite.Create();
begin
	inherited;

	Scenario(@self.CreateTest, 'should construct and destruct');
	Scenario(@self.ObviousCalcTest, 'should parse a very simple calculation');
end;

procedure TBaseSuite.CreateTest();
var
	vCalc: TPN;
begin

	try
		vCalc := TPN.Create;
		vCalc.Free;
		TestPass('no exception');
	except
		on E: Exception do begin
			Fatal;
			TestFail('exception occured: ' + E.Message, 'no exception');
		end;
	end;
end;

procedure TBaseSuite.ObviousCalcTest();
var
	vCalc: TPN;
begin
	vCalc := TPN.Create;
	vCalc.ParseString('2 + 2');

	Fatal;
	TestWithin(vCalc.GetResult, 4, cSmallPrecision, 'result ok');
	vCalc.Free;
end;

end.

