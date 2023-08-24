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

{ Handler for separating , }
function OpSeparator(vStack: TPNNumberStack): TNumber;
begin
	// this does nothing (as is should)
	result := NextArg(vStack);
end;

{ Handler for unary - }
function OpMinus(vStack: TPNNumberStack): TNumber;
begin
	result := -1 * NextArg(vStack);
end;

{ Handler for function ln }
function OpLogN(vStack: TPNNumberStack): TNumber;
begin
	result := LnXP1(NextArg(vStack));
end;

{ Handler for function log }
function OpLog(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := LogN(result, NextArg(vStack));
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

{ Handler for // }
function OpDiv(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := Floor(result / NextArg(vStack));
end;

{ Handler for function sqrt }
function OpSqrt(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack) ** 0.5;
end;

{ Handler for function sin }
function OpSin(vStack: TPNNumberStack): TNumber;
begin
	result := Sin(NextArg(vStack));
end;

{ Handler for function cos }
function OpCos(vStack: TPNNumberStack): TNumber;
begin
	result := Cos(NextArg(vStack));
end;

{ Handler for function tan }
function OpTan(vStack: TPNNumberStack): TNumber;
begin
	result := Tan(NextArg(vStack));
end;

{ Handler for function cot }
function OpCot(vStack: TPNNumberStack): TNumber;
begin
	result := Cotan(NextArg(vStack));
end;

{ Handler for function arcsin }
function OpArcSin(vStack: TPNNumberStack): TNumber;
begin
	result := ArcSin(NextArg(vStack));
end;

{ Handler for function arccos }
function OpArcCos(vStack: TPNNumberStack): TNumber;
begin
	result := ArcCos(NextArg(vStack));
end;

{ Handler for function rand }
{ Note: Randomization must be performed by program running the calculator }
function OpRand(vStack: TPNNumberStack): TNumber;
begin
	result := Random(Floor(NextArg(vStack)));
end;

{ Handler for function min }
function OpMin(vStack: TPNNumberStack): TNumber;
begin
	result := Min(NextArg(vStack), NextArg(vStack));
end;

{ Handler for function max }
function OpMax(vStack: TPNNumberStack): TNumber;
begin
	result := Max(NextArg(vStack), NextArg(vStack));
end;

{ Handler for function round }
function OpRound(vStack: TPNNumberStack): TNumber;
begin
	result := Round(NextArg(vStack));
end;

{ Handler for function floor }
function OpFloor(vStack: TPNNumberStack): TNumber;
begin
	result := Floor(NextArg(vStack));
end;

{ Handler for function ceil }
function OpCeil(vStack: TPNNumberStack): TNumber;
begin
	result := Ceil(NextArg(vStack));
end;

{ Handler for function sign }
function OpSign(vStack: TPNNumberStack): TNumber;
begin
	result := Sign(NextArg(vStack));
end;

{ Handler for function abs}
function OpAbs(vStack: TPNNumberStack): TNumber;
begin
	result := Abs(NextArg(vStack));
end;

{ Handler for function fact }
function OpFact(vStack: TPNNumberStack): TNumber;
var
	vInd: Int64;
begin
	result := 1;
	for vInd := 2 to Floor(NextArg(vStack)) do
		result *= vInd;
end;

{ Handler for }
function OpExp(vStack: TPNNumberStack): TNumber;
begin
	result := Exp(NextArg(vStack));
end;

{ Apply handler }
function ApplyOperation(vOp: TOperationInfo; vStack: TPNNumberStack): TNumber;
begin
	case vOp.OperationType of
		otSeparator: result := OpSeparator(vStack);
		otMinus: result := OpMinus(vStack);
		otAddition: result := OpAddition(vStack);
		otSubtraction: result := OpSubtraction(vStack);
		otMultiplication: result := OpMultiplication(vStack);
		otDivision: result := OpDivision(vStack);
		otPower: result := OpPower(vStack);
		otModulo: result := OpModulo(vStack);
		otDiv: result := OpDiv(vStack);
		otSqrt: result := OpSqrt(vStack);
		otLogN: result := OpLogN(vStack);
		otLog: result := OpLog(vStack);
		otSin: result := OpSin(vStack);
		otCos: result := OpCos(vStack);
		otTan: result := OpTan(vStack);
		otCot: result := OpCot(vStack);
		otArcSin: result := OpArcSin(vStack);
		otArcCos: result := OpArcCos(vStack);
		otRand: result := OpRand(vStack);
		otMin: result := OpMin(vStack);
		otMax: result := OpMax(vStack);
		otRound: result := OpRound(vStack);
		otFloor: result := OpFloor(vStack);
		otCeil: result := OpCeil(vStack);
		otSign: result := OpSign(vStack);
		otAbs: result := OpAbs(vStack);
		otFact: result := OpFact(vStack);
		otExp: result := OpExp(vStack);
	end;
end;

{ Tries to fetch a variable value from TVariableMap }
function ResolveVariable(const vItem: TItem; vVariables: TVariableMap): TNumber;
begin
	if not vVariables.TryGetData(vItem.VariableName, result) then
		raise EUnknownVariable.Create('Variable ' + vItem.VariableName + ' was not defined');
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
			raise EInvalidExpression.Create('Invalid expression');

	finally
		while not vMainStackCopy.Empty do
			vMainStack.Push(vMainStackCopy.Pop);

		vLocalStack.Free;
		vMainStackCopy.Free;
	end;
end;

end.

