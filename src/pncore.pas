unit PNCore;

{$mode objfpc}{$H+}{$J-}

{
	Core of the PN system, which happens to be the definition of available operators
}

interface

uses
	fgl, Math, SysUtils,
	PNStack, PNTypes;

type
	TOperationHandler = function (const stack: TPNStack): TNumber;
	TOperationInfo = packed record
		handler: TOperationHandler;
		priority: Byte;
	end;

	TOperationsMap = specialize TFPGMap<TOperator, TOperationInfo>;

function GetOperationsMap(): TOperationsMap;

implementation

function NextArg(const stack: TPNStack): TNumber;
var
	popped: TItem;

begin
	if stack.Empty() then
		raise Exception.Create('Invalid Polish notation');

	popped := stack.Pop();

	if popped.itemType <> itNumber then
		raise Exception.Create('Invalid Polish notation');

	result := popped.number;
end;

{ Handler for + }
function OpAddition(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := result + NextArg(stack);
end;

{ Handler for - }
function OpSubstraction(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := result - NextArg(stack);
end;

{ Handler for * }
function OpMultiplication(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := result * NextArg(stack);
end;

{ Handler for / }
function OpDivision(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := result / NextArg(stack);
end;

{ Handler for ^ }
function OpPower(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := result ** NextArg(stack);
end;

{ Handler for % }
function OpModulo(const stack: TPNStack): TNumber;
begin
	result := NextArg(stack);
	result := FMod(result, NextArg(stack));
end;

{ Creates a new TOperationInfo }
function MakeInfo(const handler: TOperationHandler; const priority: Byte): TOperationInfo;
begin
	result.handler := handler;
	result.priority := priority;
end;

function GetOperationsMap(): TOperationsMap;
begin
	result := TOperationsMap.Create;

	result.Add('+', MakeInfo(@OpAddition, 1));
	result.Add('-', MakeInfo(@OpSubstraction, 1));
	result.Add('*', MakeInfo(@OpMultiplication, 2));
	result.Add('/', MakeInfo(@OpDivision, 2));
	result.Add('%', MakeInfo(@OpModulo, 2));
	result.Add('^', MakeInfo(@OpPower, 3));
end;

end.
