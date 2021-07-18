unit PNParser;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNCore, PNStack, PNTypes;

function Parse(const input: String): TPNStack;

implementation

// each bracket pair creates a new context for ParsePartial
procedure ParsePartial(const context: String; const stack: TPNStack);
begin
end;

function Parse(const input: String): TPNStack;
begin
	result := TPNStack.Create;
	ParsePartial(input, result);
end;

end.
