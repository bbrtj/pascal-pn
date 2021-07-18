program PNCLI;

{$mode objfpc}{$H+}{$J-}

{
	CLI program using the PN system
}

uses
	PN;

var
	calc: TPN;
begin
	calc := TPN.Create;
	calc.ImportString('++#2#+*#3#4');
	WriteLn(calc.GetResult());

	calc.ImportString('+-#2#1');
	WriteLn(calc.GetResult());

	calc.ImportString('+-#+^#5#2#+*#2#6.0E+1');
	WriteLn(calc.GetResult());

	calc.ImportString('+*#3#$test');
	calc.DefineVariable('test', 80);
	WriteLn(calc.GetResult());
end.

