unit RPN;

{$mode objfpc}{$H+}{$J-}

interface

uses
	RPNTypes, RPNStack;

function Parse(input: String): TStack;
function Calculate(parsed: TStack; variables: TVariableMap): TNumber;

implementation

function Parse(input: String): TStack;
begin
end;

function Calculate(parsed: TStack; variables: TVariableMap): TNumber;
begin
end;

end.
