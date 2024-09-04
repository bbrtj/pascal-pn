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
function NextArg(Stack: TPNCalculationStack): TNumber;
begin
	if Stack.Empty() then
		raise EStackError.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := Stack.Pop();
end;

function NextList(Stack: TPNCalculationStack): TNumberList;
begin
	if Stack.Empty() then
		raise EStackError.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := Stack.PopList();
end;

{ Handler for separating , }
procedure OpSeparator(Stack: TPNCalculationStack);
var
	List: TNumberList;
begin
	List := NextList(Stack);
	while List.Count > 1 do
		Stack.AddToTop(List.Pop);

	Stack.AddToTop(List.Number);
end;

{ Handler for unary - }
procedure OpMinus(Stack: TPNCalculationStack);
begin
	Stack.Push(-1 * NextArg(Stack));
end;

{ Handler for function ln }
procedure OpLogN(Stack: TPNCalculationStack);
begin
	Stack.Push(LnXP1(NextArg(Stack)));
end;

{ Handler for function log }
procedure OpLog(Stack: TPNCalculationStack);
var
	List: TNumberList;
begin
	List := NextList(Stack);
	if List.Count <> 2 then
		raise EStackError.Create('Expected list of 2 elements, got ' + IntToStr(List.Count));

	Stack.Push(LogN(List.Pop, List.Number));
end;

{ Handler for + }
procedure OpAddition(Stack: TPNCalculationStack);
begin
	Stack.Push(NextArg(Stack) + NextArg(Stack));
end;

{ Handler for - }
procedure OpSubtraction(Stack: TPNCalculationStack);
begin
	Stack.Push(NextArg(Stack) - NextArg(Stack));
end;

{ Handler for * }
procedure OpMultiplication(Stack: TPNCalculationStack);
begin
	Stack.Push(NextArg(Stack) * NextArg(Stack));
end;

{ Handler for / }
procedure OpDivision(Stack: TPNCalculationStack);
begin
	Stack.Push(NextArg(Stack) / NextArg(Stack));
end;

{ Handler for ^ }
procedure OpPower(Stack: TPNCalculationStack);
var
	LNum: TNumber;
begin
	LNum := NextArg(Stack);
	Stack.Push(LNum ** NextArg(Stack));
end;

{ Handler for % }
procedure OpModulo(Stack: TPNCalculationStack);
var
	LNum: TNumber;
begin
	LNum := NextArg(Stack);
	Stack.Push(FMod(LNum, NextArg(Stack)));
end;

{ Handler for // }
procedure OpDiv(Stack: TPNCalculationStack);
begin
	Stack.Push(Floor64(NextArg(Stack) / NextArg(Stack)));
end;

{ Handler for function sqrt }
procedure OpSqrt(Stack: TPNCalculationStack);
begin
	Stack.Push(NextArg(Stack) ** 0.5);
end;

{ Handler for function sin }
procedure OpSin(Stack: TPNCalculationStack);
begin
	Stack.Push(Sin(NextArg(Stack)));
end;

{ Handler for function cos }
procedure OpCos(Stack: TPNCalculationStack);
begin
	Stack.Push(Cos(NextArg(Stack)));
end;

{ Handler for function tan }
procedure OpTan(Stack: TPNCalculationStack);
begin
	Stack.Push(Tan(NextArg(Stack)));
end;

{ Handler for function cot }
procedure OpCot(Stack: TPNCalculationStack);
begin
	Stack.Push(Cotan(NextArg(Stack)));
end;

{ Handler for function arcsin }
procedure OpArcSin(Stack: TPNCalculationStack);
begin
	Stack.Push(ArcSin(NextArg(Stack)));
end;

{ Handler for function arccos }
procedure OpArcCos(Stack: TPNCalculationStack);
begin
	Stack.Push(ArcCos(NextArg(Stack)));
end;

{ Handler for function rand }
{ Note: Randomization must be performed by program running the calculator }
procedure OpRand(Stack: TPNCalculationStack);
begin
	Stack.Push(Random(Floor64(NextArg(Stack))));
end;

{ Handler for function min }
procedure OpMin(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LMin: TNumber;
begin
	List := NextList(Stack);

	LMin := List.Number;
	while List.Count > 1 do
		LMin := Min(LMin, List.Pop);

	Stack.Push(LMin);
end;

{ Handler for function max }
procedure OpMax(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LMax: TNumber;
begin
	List := NextList(Stack);

	LMax := List.Number;
	while List.Count > 1 do
		LMax := Max(LMax, List.Pop);

	Stack.Push(LMax);
end;

{ Handler for function round }
procedure OpRound(Stack: TPNCalculationStack);
begin
	Stack.Push(Round(NextArg(Stack)));
end;

{ Handler for function floor }
procedure OpFloor(Stack: TPNCalculationStack);
begin
	Stack.Push(Floor64(NextArg(Stack)));
end;

{ Handler for function ceil }
procedure OpCeil(Stack: TPNCalculationStack);
begin
	Stack.Push(Ceil64(NextArg(Stack)));
end;

{ Handler for function sign }
procedure OpSign(Stack: TPNCalculationStack);
begin
	Stack.Push(Sign(NextArg(Stack)));
end;

{ Handler for function abs}
procedure OpAbs(Stack: TPNCalculationStack);
begin
	Stack.Push(Abs(NextArg(Stack)));
end;

{ Handler for function fact }
procedure OpFact(Stack: TPNCalculationStack);
var
	I: Int64;
	LFact: TNumber;
begin
	LFact := 1;
	for I := 2 to Floor64(NextArg(Stack)) do
		LFact *= I;

	Stack.Push(LFact);
end;

{ Handler for }
procedure OpExp(Stack: TPNCalculationStack);
begin
	Stack.Push(Exp(NextArg(Stack)));
end;

{ Apply handler }
procedure ApplyOperation(Op: TOperationInfo; Stack: TPNCalculationStack);
begin
	case Op.OperationType of
		otSeparator: OpSeparator(Stack);
		otMinus: OpMinus(Stack);
		otAddition: OpAddition(Stack);
		otSubtraction: OpSubtraction(Stack);
		otMultiplication: OpMultiplication(Stack);
		otDivision: OpDivision(Stack);
		otPower: OpPower(Stack);
		otModulo: OpModulo(Stack);
		otDiv: OpDiv(Stack);
		otSqrt: OpSqrt(Stack);
		otLogN: OpLogN(Stack);
		otLog: OpLog(Stack);
		otSin: OpSin(Stack);
		otCos: OpCos(Stack);
		otTan: OpTan(Stack);
		otCot: OpCot(Stack);
		otArcSin: OpArcSin(Stack);
		otArcCos: OpArcCos(Stack);
		otRand: OpRand(Stack);
		otMin: OpMin(Stack);
		otMax: OpMax(Stack);
		otRound: OpRound(Stack);
		otFloor: OpFloor(Stack);
		otCeil: OpCeil(Stack);
		otSign: OpSign(Stack);
		otAbs: OpAbs(Stack);
		otFact: OpFact(Stack);
		otExp: OpExp(Stack);
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
	LLocalStack: TPNCalculationStack;
	LItem: TItem;

begin
	LLocalStack := TPNCalculationStack.Create;
	MainStackCopy := TPNStack.Create;

	try
		// main calculation loop
		while not MainStack.Empty() do begin
			LItem := MainStack.Pop();
			MainStackCopy.Push(LItem);

			case LItem.ItemType of
				itOperator: ApplyOperation(LItem.Operation, LLocalStack);
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

