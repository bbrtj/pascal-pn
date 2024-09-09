unit CalcTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, Math, SysUtils;

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
		procedure SqrtTest();
		procedure RandTest();
		procedure TrigTest();
		procedure IntegerDivisionTest();
		procedure FactorialTest();
		procedure ExpTest();
		procedure CountTest();
		procedure MinMaxTest();
		procedure SumAvgTest();
		procedure RangeTest();
		procedure SignTest();
		procedure AbsTest();
		procedure RoundTest();

		procedure VariablesTest();
		procedure PrecedenceTest();
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
	Scenario(@self.SqrtTest, 'should calculate square root');
	Scenario(@self.RandTest, 'should yield random numbers');
	Scenario(@self.TrigTest, 'should calculate trigonometric functions');
	Scenario(@self.IntegerDivisionTest, 'should be able to perform integer division');
	Scenario(@self.FactorialTest, 'should calculate factorial');
	Scenario(@self.ExpTest, 'should calculate exponent');
	Scenario(@self.CountTest, 'should calculate count');
	Scenario(@self.MinMaxTest, 'should calculate min/max');
	Scenario(@self.SumAvgTest, 'should calculate sum/avg');
	Scenario(@self.RangeTest, 'should handle ranges');
	Scenario(@self.SignTest, 'should calculate sign of a variable');
	Scenario(@self.AbsTest, 'should calculate absolute value');
	Scenario(@self.RoundTest, 'should be able to perform rounding');
	Scenario(@self.VariablesTest, 'should be able to use variables');
	Scenario(@self.PrecedenceTest, 'should respect operator precedence');
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

	FCalc.ParseString('log 1 + 1, 128 + 128 ');
	TestWithin(FCalc.GetResult, LogN(2, 256), cSmallPrecision);
end;

procedure TCalculationsSuite.SqrtTest();
begin
	FCalc.ParseString('sqrt 25');
	TestWithin(FCalc.GetResult, 5, cSmallPrecision);

	FCalc.ParseString('sqrt 10000');
	TestWithin(FCalc.GetResult, 100, cSmallPrecision);
end;

procedure TCalculationsSuite.RandTest();
var
	LResult: Double;
begin
	FCalc.ParseString('rand 15156512');
	LResult := FCalc.GetResult;

	FCalc.ParseString('rand 15156512');
	TestOk(FCalc.GetResult <> LResult);
end;

procedure TCalculationsSuite.TrigTest();
begin
	FCalc.ParseString('sin 51.5');
	TestWithin(FCalc.GetResult, Sin(51.5), cSmallPrecision, 'sinus');

	FCalc.ParseString('cos 51.5');
	TestWithin(FCalc.GetResult, Cos(51.5), cSmallPrecision, 'cosinus');

	FCalc.ParseString('tan 51.5');
	TestWithin(FCalc.GetResult, Tan(51.5), cSmallPrecision, 'tangent');

	FCalc.ParseString('cot 51.5');
	TestWithin(FCalc.GetResult, Cotan(51.5), cSmallPrecision, 'cotangent');

	FCalc.ParseString('arcsin 0.7');
	TestWithin(FCalc.GetResult, ArcSin(0.7), cSmallPrecision, 'arcus sinus');

	FCalc.ParseString('arccos 0.7');
	TestWithin(FCalc.GetResult, ArcCos(0.7), cSmallPrecision, 'arcus cosinus');
end;

procedure TCalculationsSuite.IntegerDivisionTest();
begin
	FCalc.ParseString('5120 div 15');
	TestWithin(FCalc.GetResult, 5120 div 15, cSmallPrecision, 'integer division');
end;

procedure TCalculationsSuite.FactorialTest();
begin
	FCalc.ParseString('fact 10');
	TestWithin(FCalc.GetResult, 3628800, cSmallPrecision, 'factorial');
end;

procedure TCalculationsSuite.ExpTest();
begin
	FCalc.ParseString('exp 19');
	TestWithin(FCalc.GetResult, Exp(19), cSmallPrecision, 'exponent');
end;

procedure TCalculationsSuite.CountTest();
begin
	FCalc.ParseString('count 2, 3, 4');
	TestWithin(FCalc.GetResult, 3, cSmallPrecision, 'count 3');

	FCalc.ParseString('count 1 .. 0');
	TestWithin(FCalc.GetResult, 0, cSmallPrecision, 'count 0');

	FCalc.ParseString('count 15');
	TestWithin(FCalc.GetResult, 1, cSmallPrecision, 'count 1');

	FCalc.ParseString('count 1 .. 100');
	TestWithin(FCalc.GetResult, 100, cSmallPrecision, 'count 100');
end;

procedure TCalculationsSuite.MinMaxTest();
begin
	FCalc.ParseString('min 6, 8');
	TestWithin(FCalc.GetResult, 6, cSmallPrecision, 'min');

	FCalc.ParseString('min 6, 8, 7, -3, 15, 0');
	TestWithin(FCalc.GetResult, -3, cSmallPrecision, 'min with many arguments');

	FCalc.ParseString('max 6, 8');
	TestWithin(FCalc.GetResult, 8, cSmallPrecision, 'max');

	FCalc.ParseString('max 6, 8, 7, -3, 15, 0');
	TestWithin(FCalc.GetResult, 15, cSmallPrecision, 'max with many arguments');
end;

procedure TCalculationsSuite.SumAvgTest();
begin
	FCalc.ParseString('sum 6, 8, 7, -3, 15, 0');
	TestWithin(FCalc.GetResult, 33, cSmallPrecision, 'sum');

	FCalc.ParseString('avg 6, 8, 7, -3, 15, 0');
	TestWithin(FCalc.GetResult, 33 / 6, cSmallPrecision, 'avg');
end;

procedure TCalculationsSuite.RangeTest();
begin
	FCalc.ParseString('sum 1 .. 1');
	TestWithin(FCalc.GetResult, 1, cSmallPrecision, 'equal');

	FCalc.ParseString('sum 1 .. 2');
	TestWithin(FCalc.GetResult, 3, cSmallPrecision, 'higher');

	FCalc.ParseString('sum 2 .. 1');
	TestWithin(FCalc.GetResult, 0, cSmallPrecision, 'smaller');

	FCalc.ParseString('sum 1 + 2 .. 2 + 2');
	TestWithin(FCalc.GetResult, 7, cSmallPrecision, 'precedence (plus)');

	FCalc.ParseString('sum 1 .. 3, 4');
	TestWithin(FCalc.GetResult, 10, cSmallPrecision, 'precedence (comma)');

	FCalc.ParseString('avg 1 .. 1000');
	TestWithin(FCalc.GetResult, 500.5, cSmallPrecision, 'long list');
end;

procedure TCalculationsSuite.SignTest();
begin
	FCalc.ParseString('sign 156');
	TestWithin(FCalc.GetResult, 1, cSmallPrecision, 'positive');

	FCalc.ParseString('sign 0');
	TestWithin(FCalc.GetResult, 0, cSmallPrecision, 'zero');

	FCalc.ParseString('sign -0.0005124');
	TestWithin(FCalc.GetResult, -1, cSmallPrecision, 'negative');
end;

procedure TCalculationsSuite.AbsTest();
begin
	FCalc.ParseString('abs 15');
	TestWithin(FCalc.GetResult, 15, cSmallPrecision, 'positive');

	FCalc.ParseString('abs -15');
	TestWithin(FCalc.GetResult, 15, cSmallPrecision, 'negative');
end;

procedure TCalculationsSuite.RoundTest();
begin
	FCalc.ParseString('round 15.66');
	TestWithin(FCalc.GetResult, 16, cSmallPrecision, 'round');

	FCalc.ParseString('round(1e12 + 0.1)');
	TestWithin(FCalc.GetResult, 1e12, cSmallPrecision, 'big round');

	FCalc.ParseString('floor 15.66');
	TestWithin(FCalc.GetResult, 15, cSmallPrecision, 'floor');

	FCalc.ParseString('floor(1e12 + 0.1)');
	TestWithin(FCalc.GetResult, 1e12, cSmallPrecision, 'big floor');

	FCalc.ParseString('ceil 15.66');
	TestWithin(FCalc.GetResult, 16, cSmallPrecision, 'ceil');

	FCalc.ParseString('ceil(1e12 - 0.1)');
	TestWithin(FCalc.GetResult, 1e12, cSmallPrecision, 'big ceil');
end;

procedure TCalculationsSuite.VariablesTest();
begin
	FCalc.ParseString('log logv, logv');
	FCalc.DefineVariable('logv', 5);

	TestWithin(FCalc.GetResult, 1, cSmallPrecision);

	try
		FCalc.ParseString('mod mod mod');
		TestFail('variables can''t be named like operators');
	except
		on E: Exception do TestPass('got expected error: ' + E.Message);
	end;

	FCalc.ParseString('-undef');
	try
		FCalc.GetResult;
		TestFail('variables must be defined');
	except
		on E: Exception do TestPass('got expected error: ' + E.Message);
	end;
end;

procedure TCalculationsSuite.PrecedenceTest();
begin
	FCalc.ParseString('4 + 3 * 2 ** 5');
	TestWithin(FCalc.GetResult, 4 + 3 * 2 ** 5, cSmallPrecision, 'infix precedence ok');

	FCalc.ParseString('fact(fact(2) + 1) * fact(2) - 5');
	TestWithin(FCalc.GetResult, 7, cSmallPrecision, 'prefix/infix precedence ok');
end;

end.

