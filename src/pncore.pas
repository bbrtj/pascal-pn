unit PNCore;

{$mode objfpc}{$H+}{$J-}

{
	Core of the PN system, which happens to be the definition of available operators
}

interface

uses
	Math, SysUtils,
	PNStack, PNTypes;

type
	TOperationHandler = function (const stack: TPNStack): TNumber;
	TOperationType = (otInfix);
	TOperationInfo = packed record
		&operator: TOperator;
		handler: TOperationHandler;
		priority: Byte;
		operationType: TOperationType;
	end;

	TOperationsMap = Array of TOperationInfo;

function GetOperationsMap(): TOperationsMap;

implementation

{ Get the next argument from the stack, raise an exception if not possible }
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
function MakeInfo(const &operator: TOperator; const handler: TOperationHandler; const priority: Byte): TOperationInfo;
begin
	result.&operator := &operator;
	result.handler := handler;
	result.priority := priority;
	result.operationType := otInfix;
end;

function GetOperationsMap(): TOperationsMap;
begin
	result := TOperationsMap.Create(
		MakeInfo('+', @OpAddition, 1),
		MakeInfo('-', @OpSubstraction, 1),
		MakeInfo('*', @OpMultiplication, 2),
		MakeInfo('/', @OpDivision, 2),
		MakeInfo('%', @OpModulo, 2),
		MakeInfo('^', @OpPower, 3)
	);
end;

end.
