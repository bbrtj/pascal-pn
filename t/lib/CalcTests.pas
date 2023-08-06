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

		procedure MinusTest();
		procedure AdditionTest();
		procedure SubtractionTest();
		procedure MultiplicationTest();
		procedure DivisionTest();
		procedure PowerTest();
		procedure ModuloTest();
		procedure LogarithmTest();
	end;


implementation

const
	cSmallPrecision = 1E-8;

constructor TCalculationsSuite.Create();
begin
	inherited;

	Scenario(@self.MinusTest, 'should be able to perform unary minus');
	Scenario(@self.AdditionTest, 'should be able to perform addition');
	Scenario(@self.SubtractionTest, 'should be able to perform subtraction');
	Scenario(@self.MultiplicationTest, 'should be able to perform multiplication');
	Scenario(@self.DivisionTest, 'should be able to perform division');
	Scenario(@self.PowerTest, 'should be able to perform power');
	Scenario(@self.ModuloTest, 'should be able to perform modulo');
	Scenario(@self.LogarithmTest, 'should be able to calculate logarithms');
end;

procedure TCalculationsSuite.Setup();
begin
	self.FCalc := TPN.Create;
end;

procedure TCalculationsSuite.TearDown();
begin
	self.FCalc.Free;
end;

procedure TCalculationsSuite.MinusTest();
begin
	FCalc.ParseString('- 2 - 3');
	TestWithin(FCalc.GetResult, -2 - 3, cSmallPrecision);
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

	FCalc.ParseString('7.1 ** 7');

	TestWithin(FCalc.GetResult, 7.1 ** 7, cSmallPrecision);
end;

procedure TCalculationsSuite.ModuloTest();
begin
	FCalc.ParseString('256 % 3');

	TestWithin(FCalc.GetResult, 256 mod 3, cSmallPrecision);

	FCalc.ParseString('256 mod 3');

	TestWithin(FCalc.GetResult, 256 mod 3, cSmallPrecision);
end;

procedure TCalculationsSuite.LogarithmTest();
begin
	FCalc.ParseString('ln 132');

	TestWithin(FCalc.GetResult, LnXP1(132), cSmallPrecision);

	FCalc.ParseString('log(2, 256)');

	TestWithin(FCalc.GetResult, LogN(2, 256), cSmallPrecision);

	FCalc.ParseString('log 2, 256 ');

	TestWithin(FCalc.GetResult, LogN(2, 256), cSmallPrecision);

	FCalc.ParseString('log 2, 128 + 128 ');

	TestWithin(FCalc.GetResult, LogN(2, 256), cSmallPrecision);
end;

end.

