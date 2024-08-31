unit BaseTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, PNBase, SysUtils;

type
	TBaseSuite = class(TTAPSuite, ITAPSuiteEssential)
	public
		constructor Create(); override;

		procedure CreateTest();
		procedure ObviousCalcTest();
		procedure ParsedAtTest();
		procedure FastStrToFloatTest();
	end;


implementation

const
	cSmallPrecision = 1E-8;

constructor TBaseSuite.Create();
begin
	inherited;

	Scenario(@self.CreateTest, 'should construct and destruct');
	Scenario(@self.ObviousCalcTest, 'should parse a very simple calculation');
	Scenario(@self.ParsedAtTest, 'should remember string offsets where it found tokens');
	Scenario(@self.FastStrToFloatTest, 'should parse numbers from strings');
end;

procedure TBaseSuite.CreateTest();
var
	LCalc: TPN;
begin

	try
		LCalc := TPN.Create;
		LCalc.Free;
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
	LCalc: TPN;
begin
	LCalc := TPN.Create;
	LCalc.ParseString('2 + 2');

	Fatal;
	TestWithin(LCalc.GetResult, 4, cSmallPrecision, 'result ok');
	LCalc.Free;
end;

procedure TBaseSuite.ParsedAtTest();
var
	LCalc: TPN;
	LParsedArr: TItemArray;

	procedure TestItem(Ind: Integer; ItemType: TItemType; Content: String; ParsedAt: Integer);
	begin
		SubtestBegin('testing index ' + IntToStr(Ind));
		TestIs(Ord(LParsedArr[Ind].ItemType), Ord(ItemType), 'variable type ok');
		TestIs(GetItemValue(LParsedArr[Ind]), Content, 'item value ok');
		TestIs(LParsedArr[Ind].ParsedAt, ParsedAt, 'parsed at ok');
		SubtestEnd;
	end;

begin
	LCalc := TPN.Create;
	LCalc.ParseString('xx1 / 21 + 3');

	LParsedArr := LCalc.Stack.ToArray;
	TestIs(Length(LParsedArr), 5, 'parsed array length ok');

	TestItem(0, itNumber, '3', 12);
	TestItem(1, itNumber, '21', 7);
	TestItem(2, itVariable, 'xx1', 1);
	TestItem(3, itOperator, '/', 5);
	TestItem(4, itOperator, '+', 10);

	LCalc.Free;
end;

procedure TBaseSuite.FastStrToFloatTest();
	procedure TestCase(const Txt: String; Expected: TNumber; StartAt: UInt32 = 1);
	var
		I: UInt32;
		LParsed: TNumber;
	begin
		SubtestBegin('testing case "' + Txt + '" starting at index ' + IntToStr(StartAt));
		I := StartAt;
		LParsed := FastStrToFloat(Txt, I);
		if I = StartAt then
			TestFail('parsing the number has failed')
		else
			TestWithin(LParsed, Expected, cSmallPrecision, 'parsed number ok');
		SubtestEnd;
	end;

	procedure BrokenTestCase(const Txt: String; StartAt: UInt32 = 1);
	var
		I: UInt32;
		LParsed: TNumber;
	begin
		SubtestBegin('testing broken case "' + Txt + '" starting at index ' + IntToStr(StartAt));
		I := StartAt;
		LParsed := FastStrToFloat(Txt, I);
		if I = StartAt then
			TestPass('parsing the number has failed (as expected)')
		else
			TestFail('parsing the incorrect number has succeded and yielded ' + FloatToStr(LParsed));
		SubtestEnd;
	end;

begin
	TestCase('0', 0);
	TestCase('-0', 0);
	TestCase('+0', 0);
	TestCase('00', 0);
	TestCase('01', 1);
	TestCase('+01', 1);
	TestCase('-1', -1);
	TestCase('-01', -1);
	TestCase('-01.01', -1.01);
	TestCase('123456789.87654321', 123456789.87654321);
	TestCase('1.2345e2', 123.45);
	TestCase('1.2345e+2', 123.45);
	TestCase('1.2345E2', 123.45);
	TestCase('+1.2345E2', 123.45);
	TestCase('+1.2345E-1', 0.12345);
	TestCase('-1.2345E-1', -0.12345);
	TestCase('-1.2345e100', -1.2345e100);

	TestCase('With offset: 12.50', 12.5, 14);
	TestCase('With offset: -10.2e1 and then no number', -102, 14);

	BrokenTestCase('.');
	BrokenTestCase('.1');
	BrokenTestCase('1.');
	BrokenTestCase('1.e');
	BrokenTestCase('1.e1');
	BrokenTestCase('1e');
	BrokenTestCase('1ea');
	BrokenTestCase('.1e');
	BrokenTestCase('-+1');
	BrokenTestCase('+-1');
end;

end.

