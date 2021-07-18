program PNCLI;

{$mode objfpc}{$H+}{$J-}

{
	CLI program using the PN system
}

uses
	SysUtils,
	PN;

type
	TAction = (aCalculate, aExport, aHelp);

{ Read arguments from the command line and apply to the TPN instance }
function ReadArguments(const instance: TPN): TAction;
var
	paramI: Integer;
	param: String;

	valCode: Word;
	valValue: Double;

	function NextParam(): String;
	begin
		paramI += 1;

		if paramI > ParamCount() then
			raise Exception.Create('Invalid command line parameters');

		result := ParamStr(paramI);
	end;

begin
	// default action
	result := aCalculate;

	for paramI := 1 to ParamCount() do begin
		param := ParamStr(paramI);

		case param of
			'-h', '--help': Exit(aHelp);
			'-e', '--export': result := aExport;
			'-p', '--parse': instance.ParseString(NextParam());
			'-i', '--import': instance.ImportString(NextParam());
			'-v', '--var': begin
				param := NextParam();
				Val(NextParam(), valValue, valCode);

				if valCode = 0 then
					instance.DefineVariable(param, valValue)
				else
					raise Exception.Create('Value for variable ' + param + ' is not a number');
			end;
		end;
	end;
end;

{ Main program }

var
	calc: TPN;

begin
	try
		calc := TPN.Create;
		case ReadArguments(calc) of
			aHelp: begin
				WriteLn('Usage:');
				WriteLn(ParamStr(0) + ' [-h|--help] [-i|--import str] [-p|--parse str] [-e|--export] [-v|--var str num]');
				WriteLn('--help: shows this help');
				WriteLn('--import str: imports str as a Polish notation exported string');
				WriteLn('--parse str: parses str as a standard notation string');
				WriteLn('--export: export Polish notation instead of calculating');
				WriteLn('--var str num: assings value num to variable str, can be specified multiple times');
			end;
			aExport: WriteLn(calc.ExportString());
			aCalculate: WriteLn(calc.GetResult());
		end;

	except
		on err: Exception do
			WriteLn(StdErr, err.Message);
	end;
end.

