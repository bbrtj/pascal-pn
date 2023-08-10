unit ParseErrorTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, PNBase, SysUtils;

type
	TErrorClass = class of EParsingFailed;

	TParseErrorSuite = class(TTAPSuite)
	private
		FCalc: TPN;

		procedure TestForException(const vInput: String; vClass: TErrorClass);
	public
		constructor Create(); override;

		procedure Setup(); override;
		procedure TearDown(); override;

		procedure EmptyStatementTest();
		procedure UnmatchedBraceTest();
		procedure InvalidStatementTest();
	end;


implementation

procedure TParseErrorSuite.TestForException(const vInput: String; vClass: TErrorClass);
begin
	try
		FCalc.ParseString(vInput);
		TestFail('no error at all');
	except
		on E: Exception do begin
			Note('Exception message: ' + E.Message);
			TestIs(E, vClass);
		end;
	end;
end;

constructor TParseErrorSuite.Create();
begin
	inherited;

	Scenario(@self.EmptyStatementTest, 'should error on empty statement');
	Scenario(@self.UnmatchedBraceTest, 'should detect unmatched braces');
	Scenario(@self.InvalidStatementTest, 'should detect invalid statement inside braces');
end;

procedure TParseErrorSuite.Setup();
begin
	self.FCalc := TPN.Create;
end;

procedure TParseErrorSuite.TearDown();
begin
	self.FCalc.Free;
end;

procedure TParseErrorSuite.EmptyStatementTest();
begin
	self.TestForException('', EParsingFailed);
end;

procedure TParseErrorSuite.UnmatchedBraceTest();
begin
	self.TestForException('(2+3', EUnmatchedBraces);
end;

procedure TParseErrorSuite.InvalidStatementTest();
begin
	self.TestForException('(-)', EInvalidStatement);
end;

end.

