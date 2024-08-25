program PNCLI;

{$mode objfpc}{$H+}{$J-}

uses
	SysUtils, PN;

var
	Calc: TPN;
	Variable: Int64;
	Total: Double;

begin
	Total := 0;
	for Variable := 1 to 20 * 30 * 20 do begin
		Calc := TPN.Create;
		Calc.ParseString('2.81 + 3E5 / 5 * var1 ^ 4 - (8.81 - 16 * 32 + (51 * 49.999))');
		Calc.DefineVariable('var1', Variable);
		Total += Calc.GetResult();
		Calc.Free;
	end;

	writeln(Total);
end.

