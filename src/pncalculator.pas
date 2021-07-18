unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNCore, PNStack, PNTypes;

function Calculate(const parsed: TPNStack; const variables: TVariableMap): TNumber;

implementation

function Calculate(const parsed: TPNStack; const variables: TVariableMap): TNumber;
begin
end;

end.
