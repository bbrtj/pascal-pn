unit PNParser;

{$mode objfpc}{$H+}{$J-}

interface

uses
	PNCore, PNStack, PNTypes;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;

implementation

{ Parses a partial context. Each bracket pair creates a new context }
procedure ParsePartial(const context: String; const stack: TPNStack; const operators: TOperationsMap);
begin
end;

{ Parses the entire calculation }
function Parse(const input: String; const operators: TOperationsMap): TPNStack;
begin
	result := TPNStack.Create;
	ParsePartial(input, result, operators);
end;

end.
