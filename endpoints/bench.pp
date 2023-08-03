program PNCLI;

{$mode objfpc}{$H+}{$J-}

uses
	SysUtils, PN;

var
	vCalc: TPN;
	vVar: Int64;
	vTotal: Double;

begin
	vTotal := 0;
	for vVar := 1 to 20 * 30 * 20 do begin
		vCalc := TPN.Create;
		vCalc.ParseString('2 + 3 / 5 * var1 ^ 4 - (8 - 16 * 32 + (51 * 49))');
		vCalc.DefineVariable('var1', vVar);
		vTotal += vCalc.GetResult();
		vCalc.Free;
	end;

	writeln(vTotal);
end.

