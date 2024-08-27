program CLI;

{$mode objfpc}{$H+}{$J-}

{
	CLI program using the PN system
}

uses
	SysUtils,
	PN;

type
	TAction = (aParse, aImport, aExport, aHelp);
	TActionSet = set of TAction;

	TVariable = record
		Name: String;
		Value: Double;
	end;

	TVariableArray = Array of TVariable;

	TProgramArgs = record
		Actions: TActionSet;
		ToParse: String;
		ToImport: String;
		BenchCount: UInt32;
		Variables: TVariableArray;
	end;

{ Read arguments from the command line and apply to the TPN instance }

function ReadArguments(): TProgramArgs;
var
	I: Int32;
	Variable: TVariable;
	ValCode: UInt32;

	function HasNextParam(): Boolean;
	begin
		result := I < ParamCount();
	end;

	function NextParam(): String;
	begin
		I += 1;

		if I > ParamCount() then
			raise Exception.Create('Invalid command line parameters');

		result := ParamStr(I);
	end;

begin
	SetLength(result.Variables, 0);
	result.BenchCount := 1;

	I := 0;
	while HasNextParam() do begin
		case NextParam() of
			'-h', '--help': result.Actions += [aHelp];
			'-e', '--export': result.Actions += [aExport];
			'-b', '--bench': begin
				Val(NextParam(), result.BenchCount, ValCode);
				if (ValCode <> 0) or (result.BenchCount < 1) then
					raise Exception.Create('Invalid bench count');
			end;
			'-p', '--parse': begin
				result.Actions += [aParse];
				result.ToParse := NextParam();
			end;
			'-i', '--import': begin
				result.Actions += [aImport];
				result.ToImport := NextParam();
			end;
			'-v', '--var': begin
				Variable.Name := NextParam();
				Val(NextParam(), Variable.Value, ValCode);

				if ValCode = 0 then begin
					SetLength(result.Variables, Length(result.Variables) + 1);
					result.Variables[High(result.Variables)] := Variable;
				end
				else
					raise Exception.Create('Value for variable ' + Variable.Name + ' is not a number');
			end;
		end;
	end;
end;

procedure PrintHelp(Calc: TPN);
begin
	WriteLn('Usage:');
	WriteLn(ParamStr(0) + ' [-h|--help] [-i|--import str] [-p|--parse str] [-e|--export] [-v|--var str num] [-b|--bench count]');
	WriteLn('--help: shows this help');
	WriteLn('--import str: imports str as a Polish notation exported string');
	WriteLn('--parse str: parses str as a standard notation string');
	WriteLn('--export: export Polish notation instead of calculating');
	WriteLn('--var str num: assings value num to variable str, can be specified multiple times');
	WriteLn('--bench count: performs the operation count times (for benchmarking)');
	WriteLn('Operators:');
	Write(Calc.Help);
end;

{ Main program }

var
	Args: TProgramArgs;
	Calc: TPN;
	I: Int32;
	CalcResult: Double;
	CalcExportResult: String;
	SingleVar: TVariable;

begin
	try try
		Args := ReadArguments();

		for I := 1 to Args.BenchCount do begin
			Calc := TPN.Create;

			if aHelp in Args.Actions then begin
				PrintHelp(Calc);
				halt;
			end;

			if aParse in Args.Actions then
				Calc.ParseString(Args.ToParse)
			else if aImport in Args.Actions then
				Calc.ImportString(Args.ToImport)
			else
				raise Exception.Create('Must either parse or import')
			;

			for SingleVar in Args.Variables do
				Calc.DefineVariable(SingleVar.Name, SingleVar.Value);

			if aExport in Args.Actions then
				CalcExportResult := Calc.ExportString()
			else
				CalcResult := Calc.GetResult()
			;

			FreeAndNil(Calc);
		end;

		if aExport in Args.Actions then
			Write(CalcExportResult)
		else
			Write(Format('%G', [CalcResult]))
		;

	except
		on err: Exception do begin
			WriteLn(StdErr, err.Message);
			ExitCode := 1;
		end;
	end;
	finally
		Calc.Free;
	end;
end.

