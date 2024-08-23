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

end.

