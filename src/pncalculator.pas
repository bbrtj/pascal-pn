unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for getting the results of the calculation
}

interface

uses
	SysUtils,
	PNCore, PNStack, PNTypes;

function Calculate(
	const mainStack: TPNStack;
	const variables: TVariableMap;
	const operationsMap: TOperationsMap
): TNumber;

implementation

{ Gets an operation handler from the operator found on the stack }
function getOperationHandler(const item: TItem; const operationsMap: TOperationsMap): TOperationHandler; inline;
var
	info: TOperationInfo;
begin
	info := GetOperationInfoByOperator(item.&operator, operationsMap);

	if info.operationType = otSyntax then
		raise Exception.Create(Format('Cannot calculate syntax operator %S', [info.&operator]));
	result := info.handler;
end;

{ Performs an operation on a stack }
function DoOperation(const op: TOperationHandler; const stack: TPNStack): TItem; inline;
begin
	result := MakeItem(op(stack));
end;

{ Tries to fetch a variable value from TVariableMap }
function ResolveVariable(const item: TItem; const variables: TVariableMap): TItem; inline;
var
	varValue: TNumber;

begin
	if not variables.TryGetData(item.variable, varValue) then
		raise Exception.Create('Variable ' + item.variable + ' was not defined');

	result := MakeItem(varValue);
end;

{ Calculates a result from a Polish notation stack }
function Calculate(
	const mainStack: TPNStack;
	const variables: TVariableMap;
	const operationsMap: TOperationsMap
): TNumber;

var
	localStack: TPNStack;
	count: Integer;

	item: TItem;

begin
	localStack := TPNStack.Create;

	// main calculationl loop
	while not mainStack.Empty() do begin
		item := mainStack.Pop();

		if item.itemType = itOperator then
			localStack.Push(DoOperation(getOperationHandler(item, operationsMap), localStack))

		else begin
			if item.itemType = itVariable then
				item := ResolveVariable(item, variables);

			localStack.Push(item);
		end;
	end;

	count := 0;
	while not localStack.Empty() do begin
		mainStack.Push(localStack.Pop());
		count := count + 1
	end;

	FreeAndNil(localStack);

	if count <> 1 then
		raise Exception.Create('Invalid Polish notation');

	item := mainStack.Top();
	if item.itemType <> itNumber then
		raise Exception.Create('Polish notation result not a number');

	result := item.number;
end;

end.
