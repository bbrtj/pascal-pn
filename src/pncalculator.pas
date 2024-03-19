unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for getting the results of the calculation
}

interface

uses
	Math, SysUtils,
	PNStack, PNBase;

function Calculate(MainStack: TPNStack; Variables: TVariableMap): TNumber;

implementation

{ Get the next argument from the stack, raise an exception if not possible }
function NextArg(Stack: TPNNumberStack): TNumber;
begin
	if Stack.Empty() then
		raise Exception.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := Stack.Pop();
end;

{ Handler for separating , }
function OpSeparator(Stack: TPNNumberStack): TNumber;
begin
	// this does nothing (as is should)
	result := NextArg(Stack);
end;

{ Handler for unary - }
function OpMinus(Stack: TPNNumberStack): TNumber;
begin
	result := -1 * NextArg(Stack);
end;

{ Handler for function ln }
function OpLogN(Stack: TPNNumberStack): TNumber;
begin
	result := LnXP1(NextArg(Stack));
end;

{ Handler for function log }
function OpLog(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result := LogN(result, NextArg(Stack));
end;

{ Handler for + }
function OpAddition(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result += NextArg(Stack);
end;

{ Handler for - }
function OpSubtraction(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result -= NextArg(Stack);
end;

{ Handler for * }
function OpMultiplication(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result *= NextArg(Stack);
end;

{ Handler for / }
function OpDivision(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result /= NextArg(Stack);
end;

{ Handler for ^ }
function OpPower(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result := result ** NextArg(Stack);
end;

{ Handler for % }
function OpModulo(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result := FMod(result, NextArg(Stack));
end;

{ Handler for // }
function OpDiv(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack);
	result := Floor(result / NextArg(Stack));
end;

{ Handler for function sqrt }
function OpSqrt(Stack: TPNNumberStack): TNumber;
begin
	result := NextArg(Stack) ** 0.5;
end;

{ Handler for function sin }
function OpSin(Stack: TPNNumberStack): TNumber;
begin
	result := Sin(NextArg(Stack));
end;

{ Handler for function cos }
function OpCos(Stack: TPNNumberStack): TNumber;
begin
	result := Cos(NextArg(Stack));
end;

{ Handler for function tan }
function OpTan(Stack: TPNNumberStack): TNumber;
begin
	result := Tan(NextArg(Stack));
end;

{ Handler for function cot }
function OpCot(Stack: TPNNumberStack): TNumber;
begin
	result := Cotan(NextArg(Stack));
end;

{ Handler for function arcsin }
function OpArcSin(Stack: TPNNumberStack): TNumber;
begin
	result := ArcSin(NextArg(Stack));
end;

{ Handler for function arccos }
function OpArcCos(Stack: TPNNumberStack): TNumber;
begin
	result := ArcCos(NextArg(Stack));
end;

{ Handler for function rand }
{ Note: Randomization must be performed by program running the calculator }
function OpRand(Stack: TPNNumberStack): TNumber;
begin
	result := Random(Floor(NextArg(Stack)));
end;

{ Handler for function min }
function OpMin(Stack: TPNNumberStack): TNumber;
begin
	result := Min(NextArg(Stack), NextArg(Stack));
end;

{ Handler for function max }
function OpMax(Stack: TPNNumberStack): TNumber;
begin
	result := Max(NextArg(Stack), NextArg(Stack));
end;

{ Handler for function round }
function OpRound(Stack: TPNNumberStack): TNumber;
begin
	result := Round(NextArg(Stack));
end;

{ Handler for function floor }
function OpFloor(Stack: TPNNumberStack): TNumber;
begin
	result := Floor(NextArg(Stack));
end;

{ Handler for function ceil }
function OpCeil(Stack: TPNNumberStack): TNumber;
begin
	result := Ceil(NextArg(Stack));
end;

{ Handler for function sign }
function OpSign(Stack: TPNNumberStack): TNumber;
begin
	result := Sign(NextArg(Stack));
end;

{ Handler for function abs}
function OpAbs(Stack: TPNNumberStack): TNumber;
begin
	result := Abs(NextArg(Stack));
end;

{ Handler for function fact }
function OpFact(Stack: TPNNumberStack): TNumber;
var
	LInd: Int64;
begin
	result := 1;
	for LInd := 2 to Floor(NextArg(Stack)) do
		result *= LInd;
end;

{ Handler for }
function OpExp(Stack: TPNNumberStack): TNumber;
begin
	result := Exp(NextArg(Stack));
end;

{ Apply handler }
function ApplyOperation(Op: TOperationInfo; Stack: TPNNumberStack): TNumber;
begin
	case Op.OperationType of
		otSeparator: result := OpSeparator(Stack);
		otMinus: result := OpMinus(Stack);
		otAddition: result := OpAddition(Stack);
		otSubtraction: result := OpSubtraction(Stack);
		otMultiplication: result := OpMultiplication(Stack);
		otDivision: result := OpDivision(Stack);
		otPower: result := OpPower(Stack);
		otModulo: result := OpModulo(Stack);
		otDiv: result := OpDiv(Stack);
		otSqrt: result := OpSqrt(Stack);
		otLogN: result := OpLogN(Stack);
		otLog: result := OpLog(Stack);
		otSin: result := OpSin(Stack);
		otCos: result := OpCos(Stack);
		otTan: result := OpTan(Stack);
		otCot: result := OpCot(Stack);
		otArcSin: result := OpArcSin(Stack);
		otArcCos: result := OpArcCos(Stack);
		otRand: result := OpRand(Stack);
		otMin: result := OpMin(Stack);
		otMax: result := OpMax(Stack);
		otRound: result := OpRound(Stack);
		otFloor: result := OpFloor(Stack);
		otCeil: result := OpCeil(Stack);
		otSign: result := OpSign(Stack);
		otAbs: result := OpAbs(Stack);
		otFact: result := OpFact(Stack);
		otExp: result := OpExp(Stack);
	end;
end;

{ Tries to fetch a variable value from TVariableMap }
function ResolveVariable(const Item: TItem; Variables: TVariableMap): TNumber;
begin
	if not Variables.TryGetData(Item.VariableName, result) then
		raise EUnknownVariable.Create('Variable ' + Item.VariableName + ' was not defined');
end;


{ Calculates a result from a Polish notation stack }
function Calculate(MainStack: TPNStack; Variables: TVariableMap): TNumber;
var
	MainStackCopy: TPNStack;
	LLocalStack: TPNNumberStack;
	LItem: TItem;

begin
	LLocalStack := TPNNumberStack.Create;
	MainStackCopy := TPNStack.Create;

	try
		// main calculation loop
		while not MainStack.Empty() do begin
			LItem := MainStack.Pop();
			MainStackCopy.Push(LItem);

			case LItem.ItemType of
				itOperator: LLocalStack.Push(ApplyOperation(LItem.Operation, LLocalStack));
				itVariable: LLocalStack.Push(ResolveVariable(LItem, Variables));
				itNumber: LLocalStack.Push(LItem.Number);
			end;
		end;

		result := LLocalStack.Pop();

		if not LLocalStack.Empty then
			raise EInvalidExpression.Create('Invalid expression');

	finally
		while not MainStackCopy.Empty do
			MainStack.Push(MainStackCopy.Pop);

		LLocalStack.Free;
		MainStackCopy.Free;
	end;
end;

end.

