unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNCore, PNStack, PNTypes;

function Calculate(parsed: TPNStack; variables: TVariableMap): TNumber;

implementation

function Calculate(parsed: TPNStack; variables: TVariableMap): TNumber;
begin
end;

end.
