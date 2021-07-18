unit PNParser;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNCore, PNStack, PNTypes;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;

implementation

// each bracket pair creates a new context for ParsePartial
procedure ParsePartial(const context: String; const stack: TPNStack; const operators: TOperationsMap);
begin
end;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;
begin
	result := TPNStack.Create;
	ParsePartial(input, result, operators);
end;

end.
