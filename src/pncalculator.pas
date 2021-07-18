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
function getOperationHandler(const item: TItem; const operationsMap: TOperationsMap): TOperationHandler;
var
	found: Boolean;
	info: TOperationInfo;

begin
	found := operationsMap.TryGetData(item.&operator, info);

	if not found then
		raise Exception.Create('Invalid operator ' + item.&operator);

	result := info.handler;
end;

{ Performs an operation on a stack }
function DoOperation(const op: TOperationHandler; const stack: TPNStack): TItem;
var
	args: Array[0 .. 1] of TItem;
	current: Integer;

begin
	for current := Low(args) to High(args) do begin
		if stack.Empty() then
			raise Exception.Create('Invalid Polish notation');

		args[current] := stack.Pop();

		if args[current].itemType <> itNumber then
			raise Exception.Create('Invalid Polish notation');
	end;

	result := MakeItem(op(args[0].number, args[1].number));
end;

{ Tries to fetch a variable value from TVariableMap }
{ TODO check whether the value was found }
function ResolveVariable(const item: TItem; const variables: TVariableMap): TItem;
var
	varAssignment: TVariableAssignment;

begin
	for varAssignment in variables do begin
		if item.variable = varAssignment.variable then begin
			result := MakeItem(varAssignment.number);
			break;
		end;
	end;
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
