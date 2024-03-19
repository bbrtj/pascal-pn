unit ParseErrorTests;

{$mode objfpc}{$H+}{$J-}

interface

uses TAPSuite, TAP, PN, PNBase, SysUtils;

type
	TErrorClass = class of EParsingFailed;

	TParseErrorSuite = class(TTAPSuite)
	private
		FCalc: TPN;

		procedure TestForException(const InputString: String; ErrorClass: TErrorClass);
	public
		constructor Create(); override;

		procedure Setup(); override;
		procedure TearDown(); override;

		procedure EmptyStatementTest();
		procedure UnmatchedBraceTest();
		procedure InvalidStatementTest();
		procedure InvalidVariablesTest();
	end;


implementation

procedure TParseErrorSuite.TestForException(const InputString: String; ErrorClass: TErrorClass);
begin
	try
		FCalc.ParseString(InputString);
		TestFail('no error at all');
	except
		on E: Exception do begin
			Note('Exception message: ' + E.Message);
			TestIs(E, ErrorClass);
		end;
	end;
end;

constructor TParseErrorSuite.Create();
begin
	inherited;

	Scenario(@self.EmptyStatementTest, 'should error on empty statement');
	Scenario(@self.UnmatchedBraceTest, 'should detect unmatched braces');
	Scenario(@self.InvalidStatementTest, 'should detect invalid statement inside braces');
	Scenario(@self.InvalidVariablesTest, 'should reject invalid variable names');
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

procedure TParseErrorSuite.InvalidVariablesTest();
begin
	try
		FCalc.DefineVariable(' test ', 5);
		TestPass('variable name with around spaces ok');
	except
		on E: Exception do TestFail('variable name with around spaces not ok');
	end;

	try
		FCalc.DefineVariable('test not', 5);
		TestFail;
	except
		on E: Exception do TestIs(E, EInvalidVariableName, 'invalid variable name ok');
	end;
end;


end.

