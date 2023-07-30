program ParseTest;

{$mode objfpc}{$H+}{$J-}

uses TAP, PN, SysUtils;

const
	cSmallPrecision = 1E-10;

var
	vCalc: TPN;

begin
	SubtestBegin('should create and free without exception');
	try
		vCalc := TPN.Create;
		vCalc.Free;
		TestPass('no exception - ok');
	except
		on Exception do TestFail('exception occured');
	end;
	SubtestEnd;

	SubtestBegin('should parse a simple calculation');
	vCalc := TPN.Create;
	vCalc.ParseString('2 + 2');
	TestWithin(vCalc.GetResult, 4, cSmallPrecision, 'result ok');
	SubtestEnd;

	DoneTesting;
end.

