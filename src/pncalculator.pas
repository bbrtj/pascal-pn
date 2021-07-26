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

{ Calculates a result from a Polish notation stack }
function Calculate(
	const mainStack: TPNStack;
	const variables: TVariableMap;
	const operationsMap: TOperationsMap
): TNumber;

	{ Tries to fetch a variable value from TVariableMap }
	function ResolveVariable(const item: TItem; const variables: TVariableMap): TNumber; inline;
	var
		varValue: TNumber;

	begin
		if not variables.TryGetData(item.variable, varValue) then
			raise Exception.Create('Variable ' + item.variable + ' was not defined');

		result := varValue;
	end;

var
	localStack: TPNNumberStack;
	item: TItem;

begin
	localStack := TPNNumberStack.Create;

	// main calculation loop
	while not mainStack.Empty() do begin
		item := mainStack.Pop();

		if item.itemType = itOperator then
			localStack.Push(GetOperationInfoByOperator(item.&operator, operationsMap, True).handler(localStack))

		else if item.itemType = itVariable then
			localStack.Push(ResolveVariable(item, variables))

		else
			localStack.Push(item.number);
	end;

	result := localStack.Pop();

	if not localStack.Empty then
		raise Exception.Create('Invalid Polish notation');
	localStack.Free();

	// any further recalculations will return the value again
	mainStack.Push(MakeItem(result));
end;

end.
