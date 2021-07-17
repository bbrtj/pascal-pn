unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNTypes, PNStack;

function Calculate(parsed: TPNStack; variables: TVariableMap): TNumber;

implementation

function Calculate(parsed: TPNStack; variables: TVariableMap): TNumber;
begin
end;

end.
