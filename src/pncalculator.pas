unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for getting the results of the calculation
}

interface

uses
	SysUtils,
	PNCore, PNStack, PNTypes;

function Calculate(vMainStack: TPNStack; vVariables: TVariableMap; vOperationsMap: TOperationsMap): TNumber;

implementation

{ Tries to fetch a variable value from TVariableMap }
function ResolveVariable(vItem: TItem; vVariables: TVariableMap): TNumber;
begin
	if not vVariables.TryGetData(vItem.VariableName, result) then
		raise Exception.Create('Variable ' + vItem.VariableName + ' was not defined');
end;


{ Calculates a result from a Polish notation stack }
function Calculate(vMainStack: TPNStack; vVariables: TVariableMap; vOperationsMap: TOperationsMap): TNumber;
var
	vLocalStack: TPNNumberStack;
	vItem: TItem;

begin
	vLocalStack := TPNNumberStack.Create;

	// main calculation loop
	while not vMainStack.Empty() do begin
		vItem := vMainStack.Pop();

		if vItem.ItemType = itOperator then
			vLocalStack.Push(
				GetOperationInfoByOperator(vItem.OperatorName, vOperationsMap, True).Handler(
					vLocalStack
				)
			)

		else if vItem.ItemType = itVariable then
			vLocalStack.Push(ResolveVariable(vItem, vVariables))

		else
			vLocalStack.Push(vItem.Number);
	end;

	result := vLocalStack.Pop();

	if not vLocalStack.Empty then
		raise Exception.Create('Invalid Polish notation');

	vLocalStack.Free();

	// any further recalculations will return the value again
	vMainStack.Push(MakeItem(result));
end;

end.

