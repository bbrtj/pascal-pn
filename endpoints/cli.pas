program PNCLI;

{$mode objfpc}{$H+}{$J-}

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
end.

