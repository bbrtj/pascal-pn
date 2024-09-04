unit CalcErrorTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, PNBase, SysUtils;

type
	TCalcErrorSuite = class(TTAPSuite)
	private
		FCalc: TPN;

		procedure TestForException(const InputString: String; ErrorClass: TCalculationFailedClass);
	public
		constructor Create(); override;

		procedure Setup(); override;
		procedure TearDown(); override;

		procedure InvalidListTest();
	end;


implementation

procedure TCalcErrorSuite.TestForException(const InputString: String; ErrorClass: TCalculationFailedClass);
begin
	try
		FCalc.ParseString(InputString);
		FCalc.GetResult();
		TestFail('no error at all');
	except
		on E: Exception do begin
			Note('Exception message: ' + E.Message);
			TestIs(E, ErrorClass);
		end;
	end;
end;

constructor TCalcErrorSuite.Create();
begin
	inherited;

	Scenario(@self.InvalidListTest, 'should reject lists when a number is expected');
end;

procedure TCalcErrorSuite.Setup();
begin
	self.FCalc := TPN.Create;
end;

procedure TCalcErrorSuite.TearDown();
begin
	self.FCalc.Free;
end;

procedure TCalcErrorSuite.InvalidListTest();
begin
	self.TestForException('2, 2', ENotAggregated);
end;

end.

