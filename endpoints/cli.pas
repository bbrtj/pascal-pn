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
end.

