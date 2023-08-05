unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for getting the results of the calculation
}

interface

uses
	Math, SysUtils,
	PNStack, PNBase;

function Calculate(vMainStack: TPNStack; vVariables: TVariableMap): TNumber;

implementation

{ Get the next argument from the stack, raise an exception if not possible }
function NextArg(vStack: TPNNumberStack): TNumber;
begin
	if vStack.Empty() then
		raise Exception.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := vStack.Pop();
end;

{ Handler for unary - }
function OpMinus(vStack: TPNNumberStack): TNumber;
begin
	result := -1 * NextArg(vStack);
end;

{ Handler for + }
function OpAddition(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result += NextArg(vStack);
end;

{ Handler for - }
function OpSubtraction(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result -= NextArg(vStack);
end;

{ Handler for * }
function OpMultiplication(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result *= NextArg(vStack);
end;

{ Handler for / }
function OpDivision(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result /= NextArg(vStack);
end;

{ Handler for ^ }
function OpPower(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := result ** NextArg(vStack);
end;

{ Handler for % }
function OpModulo(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := FMod(result, NextArg(vStack));
end;

{ Apply handler }
function ApplyOperation(vOp: TOperationInfo; vStack: TPNNumberStack): TNumber;
begin
	case vOp.OperationType of
		otMinus: result := OpMinus(vStack);
		otAddition: result := OpAddition(vStack);
		otSubtraction: result := OpSubtraction(vStack);
		otMultiplication: result := OpMinus(vStack);
		otDivision: result := OpDivision(vStack);
		otPower: result := OpPower(vStack);
		otModulo: result := OpModulo(vStack);
	end;
end;

{ Tries to fetch a variable value from TVariableMap }
function ResolveVariable(vItem: TItem; vVariables: TVariableMap): TNumber;
begin
	if not vVariables.TryGetData(vItem.VariableName, result) then
		raise Exception.Create('Variable ' + vItem.VariableName + ' was not defined');
end;


{ Calculates a result from a Polish notation stack }
function Calculate(vMainStack: TPNStack; vVariables: TVariableMap): TNumber;
var
	vMainStackCopy: TPNStack;
	vLocalStack: TPNNumberStack;
	vItem: TItem;

begin
	vLocalStack := TPNNumberStack.Create;
	vMainStackCopy := TPNStack.Create;

	try
		// main calculation loop
		while not vMainStack.Empty() do begin
			vItem := vMainStack.Pop();
			vMainStackCopy.Push(vItem);

			case vItem.ItemType of
				itOperator: vLocalStack.Push(ApplyOperation(vItem.Operation, vLocalStack));
				itVariable: vLocalStack.Push(ResolveVariable(vItem, vVariables));
				itNumber: vLocalStack.Push(vItem.Number);
			end;
		end;

		result := vLocalStack.Pop();

		if not vLocalStack.Empty then
			raise Exception.Create('Invalid Polish notation');

	finally
		while not vMainStackCopy.Empty do
			vMainStack.Push(vMainStackCopy.Pop);

		vLocalStack.Free;
		vMainStackCopy.Free;

	end;
end;

end.

