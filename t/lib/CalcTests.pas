unit CalcTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, Math;

type
	TCalculationsSuite = class(TTAPSuite)
	private
		FCalc: TPN;

	public
		constructor Create(); override;

		procedure Setup(); override;
		procedure TearDown(); override;

		procedure AdditionTest();
		procedure SubtractionTest();
		procedure MultiplicationTest();
		procedure DivisionTest();
		procedure PowerTest();
		procedure ModuloTest();
	end;


implementation

const
	cSmallPrecision = 1E-8;

constructor TCalculationsSuite.Create();
begin
	inherited;

	Scenario(@self.AdditionTest, 'should be able to perform addition');
	Scenario(@self.SubtractionTest, 'should be able to perform subtraction');
	Scenario(@self.MultiplicationTest, 'should be able to perform multiplication');
	Scenario(@self.DivisionTest, 'should be able to perform division');
	Scenario(@self.PowerTest, 'should be able to perform power');
	Scenario(@self.ModuloTest, 'should be able to perform modulo');
end;

procedure TCalculationsSuite.Setup();
begin
	self.FCalc := TPN.Create;
end;

procedure TCalculationsSuite.TearDown();
begin
	self.FCalc.Free;
end;

procedure TCalculationsSuite.AdditionTest();
begin
	FCalc.ParseString('2145+888+0');

	TestWithin(FCalc.GetResult, 2145 + 888, cSmallPrecision);
end;

procedure TCalculationsSuite.SubtractionTest();
begin
	FCalc.ParseString('2145-888-0');

	TestWithin(FCalc.GetResult, 2145 - 888, cSmallPrecision);
end;

procedure TCalculationsSuite.MultiplicationTest();
begin
	FCalc.ParseString('812*16*5');

	TestWithin(FCalc.GetResult, 812 * 16 * 5, cSmallPrecision);
end;

procedure TCalculationsSuite.DivisionTest();
begin
	FCalc.ParseString('612 / 55 / 88');

	TestWithin(FCalc.GetResult, 612 / 55 / 88, cSmallPrecision);
end;

procedure TCalculationsSuite.PowerTest();
begin
	FCalc.ParseString('7.1 ^ 7');

	TestWithin(FCalc.GetResult, 7.1 ** 7, cSmallPrecision);
end;

procedure TCalculationsSuite.ModuloTest();
begin
	FCalc.ParseString('256 % 3');

	TestWithin(FCalc.GetResult, 256 mod 3, cSmallPrecision);
end;

end.
