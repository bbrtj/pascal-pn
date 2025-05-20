unit PNCalculator;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for getting the results of the calculation
}

interface

uses
	Math, SysUtils, FGL,
	PNStack, PNBase;

function Calculate(MainStack: TPNStack; Variables: TVariableMap): TNumber;

type
	TOperationInfoStore = class
	public
		type
			TOperationInfos = Array of TOperationInfo;
			TOperationMap = specialize TFPGMap<TOperatorName, TOperationInfo>;
			TOperationInfoMap = Array [TOperationCategory] of TOperationMap;

		class var
			SList: TOperationInfos;
			SMap: TOperationInfoMap;

		class constructor Create();
		class destructor Destroy;
	end;

	TOperationRunner = procedure(Stack: TPNCalculationStack);

	TFullOperationInfo = class(TOperationInfo)
	strict private
		FRunner: TOperationRunner;

	public
		constructor Create(AOperatorName: TOperatorName; ARunner: TOperationRunner;
			OC: TOperationCategory; APriority: Byte);

		property Runner: TOperationRunner read FRunner write FRunner;

	end;

implementation

const
	CMaxListLength = 1000000;

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
	List, TopList: TNumberList;
begin
	List := NextList(Stack);
	TopList := NextList(Stack);

	if Length(List) + Length(TopList) > CMaxListLength then
		raise EStackError.Create('List exceeded the maximum length');

	Stack.PushList(Concat(TopList, List));
end;

{ Handler for .. }
procedure OpRange(Stack: TPNCalculationStack);
var
	LFrom, LTo: Int64;
	I: Int64;
	LList: TNumberList;
begin
	LFrom := Floor64(NextArg(Stack));
	LTo := Floor64(NextArg(Stack));

	if LTo - LFrom + 1 > CMaxListLength then
		raise EStackError.Create('List exceeded the maximum length');

	if LFrom > LTo then
		SetLength(LList, 0)
	else
		SetLength(LList, LTo - LFrom + 1);

	for I := 0 to LTo - LFrom do
		LList[I] := LFrom + I;

	Stack.PushList(LList);
end;

{ Handler for unary - }
procedure OpMinus(Stack: TPNCalculationStack);
begin
	Stack.Push(-1 * NextArg(Stack));
end;

{ Handler for function ln }
procedure OpLogN(Stack: TPNCalculationStack);
begin
	Stack.Push(LogN(Exp(1), NextArg(Stack)));
end;

{ Handler for function log }
procedure OpLog(Stack: TPNCalculationStack);
var
	List: TNumberList;
begin
	List := NextList(Stack);
	if Length(List) <> 2 then
		raise EStackError.Create('Expected list of 2 elements, got ' + IntToStr(Length(List)));

	Stack.Push(LogN(List[1], List[0]));
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

procedure OpCount(Stack: TPNCalculationStack);
var
	List: TNumberList;
begin
	List := NextList(Stack);
	Stack.Push(Length(List));
end;

{ Handler for function min }
procedure OpMin(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LMin: TNumber;
	I: Int32;
begin
	List := NextList(Stack);

	if Length(List) > 0 then
		LMin := List[0]
	else
		LMin := 0;

	for I := 1 to High(List) do
		LMin := Min(LMin, List[I]);

	Stack.Push(LMin);
end;

{ Handler for function max }
procedure OpMax(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LMax: TNumber;
	I: Int32;
begin
	List := NextList(Stack);

	if Length(List) > 0 then
		LMax := List[0]
	else
		LMax := 0;

	for I := 1 to High(List) do
		LMax := Max(LMax, List[I]);

	Stack.Push(LMax);
end;

{ Handler for function sum }
procedure OpSum(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LSum: TNumber;
	I: Int32;
begin
	List := NextList(Stack);

	LSum := 0;
	for I := 0 to High(List) do
		LSum += List[I];

	Stack.Push(LSum);
end;

{ Handler for function avg }
procedure OpAvg(Stack: TPNCalculationStack);
var
	List: TNumberList;
	LSum: TNumber;
	LCount: UInt32;
	I: Int32;
begin
	List := NextList(Stack);

	LCount := Length(List);
	LSum := 0;
	for I := 0 to High(List) do
		LSum += List[I];

	if LCount > 0 then
		Stack.Push(LSum / LCount)
	else
		Stack.Push(0);
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
				itOperator: TFullOperationInfo(LItem.Operation).Runner(LLocalStack);
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

class constructor TOperationInfoStore.Create();
var
	LInfo: TOperationInfo;
	LOC: TOperationCategory;
begin
	TOperationInfoStore.SList := [
		TFullOperationInfo.Create(',',       @OpSeparator,       ocInfix,   5)
			.WithHelp('separates values and creates a list'),
		TFullOperationInfo.Create('..',      @OpRange,           ocInfix,   6)
			.WithHelp('creates a range of integer numbers a .. b'),
		TFullOperationInfo.Create('+',       @OpAddition,        ocInfix,   10)
			.WithHelp('addition, a plus b'),
		TFullOperationInfo.Create('-',       @OpSubtraction,     ocInfix,   10)
			.WithHelp('subtraction, a minus b'),
		TFullOperationInfo.Create('*',       @OpMultiplication,  ocInfix,   20)
			.WithHelp('multiplication, a times b'),
		TFullOperationInfo.Create('/',       @OpDivision,        ocInfix,   20)
			.WithHelp('division, a divided by b'),
		TFullOperationInfo.Create('%',       @OpModulo,          ocInfix,   20)
			.WithHelp('modulo, the remainder of a divided by b'),
		TFullOperationInfo.Create('mod',     @OpModulo,          ocInfix,   20)
			.WithHelp('modulo, the remainder of a divided by b'),
		TFullOperationInfo.Create('//',      @OpDiv,             ocInfix,   20)
			.WithHelp('integer division, division without fraction'),
		TFullOperationInfo.Create('div',     @OpDiv,             ocInfix,   20)
			.WithHelp('integer division, division without fraction'),
		TFullOperationInfo.Create('^',       @OpPower,           ocInfix,   30)
			.WithHelp('power, a to the power of b'),
		TFullOperationInfo.Create('**',      @OpPower,           ocInfix,   30)
			.WithHelp('power, a to the power of b'),

		TFullOperationInfo.Create('-',       @OpMinus,           ocPrefix,  255)
			.WithHelp('unary minus, yielding opposite number'),
		TFullOperationInfo.Create('sqrt',    @OpSqrt,            ocPrefix,  2)
			.WithHelp('f(x), square root of x'),
		TFullOperationInfo.Create('ln',      @OpLogN,            ocPrefix,  2)
			.WithHelp('f(x), natural logarithm of x (E-based)'),
		TFullOperationInfo.Create('log',     @OpLog,             ocPrefix,  2)
			.WithHelp('f(x, y), x-based logarithm of y'),
		TFullOperationInfo.Create('sin',     @OpSin,             ocPrefix,  2)
			.WithHelp('f(x), sinus of x'),
		TFullOperationInfo.Create('cos',     @OpCos,             ocPrefix,  2)
			.WithHelp('f(x), cosinus of x'),
		TFullOperationInfo.Create('tan',     @OpTan,             ocPrefix,  2)
			.WithHelp('f(x), tangent of x'),
		TFullOperationInfo.Create('cot',     @OpCot,             ocPrefix,  2)
			.WithHelp('f(x), cotangent of x'),
		TFullOperationInfo.Create('arcsin',  @OpArcSin,          ocPrefix,  2)
			.WithHelp('f(x), arcus sinus of x'),
		TFullOperationInfo.Create('arccos',  @OpArcCos,          ocPrefix,  2)
			.WithHelp('f(x), arcus cosinus of x'),
		TFullOperationInfo.Create('rand',    @OpRand,            ocPrefix,  2)
			.WithHelp('f(x), random integer from 0 to x - 1'),
		TFullOperationInfo.Create('round',   @OpRound,           ocPrefix,  2)
			.WithHelp('f(x), rounds x to the nearest integer'),
		TFullOperationInfo.Create('floor',   @OpFloor,           ocPrefix,  2)
			.WithHelp('f(x), rounds x to the nearest smaller integer'),
		TFullOperationInfo.Create('ceil',    @OpCeil,            ocPrefix,  2)
			.WithHelp('f(x), rounds x to the nearest larger integer'),
		TFullOperationInfo.Create('sign',    @OpSign,            ocPrefix,  2)
			.WithHelp('f(x), returns 1, 0 or -1 for positive, zero or negative x'),
		TFullOperationInfo.Create('abs',     @OpAbs,             ocPrefix,  2)
			.WithHelp('f(x), returns absolute value of x'),
		TFullOperationInfo.Create('fact',    @OpFact,            ocPrefix,  2)
			.WithHelp('f(x), returns factorial of x'),
		TFullOperationInfo.Create('exp',     @OpExp,             ocPrefix,  2)
			.WithHelp('f(x), returns exponent of x'),

		TFullOperationInfo.Create('count',   @OpCount,           ocPrefix,  2)
			.WithHelp('f(list), the number of elements in a list'),
		TFullOperationInfo.Create('min',     @OpMin,             ocPrefix,  2)
			.WithHelp('f(list), smallest value in a list'),
		TFullOperationInfo.Create('max',     @OpMax,             ocPrefix,  2)
			.WithHelp('f(list), largest value in a list'),
		TFullOperationInfo.Create('sum',     @OpSum,             ocPrefix,  2)
			.WithHelp('f(list), sum of list values'),
		TFullOperationInfo.Create('avg',     @OpAvg,             ocPrefix,  2)
			.WithHelp('f(list), average of list values')
	];

	for LOC in TOperationCategory do begin
		TOperationInfoStore.SMap[LOC] := TOperationInfoStore.TOperationMap.Create;
		TOperationInfoStore.SMap[LOC].Sorted := True;
		for LInfo in TOperationInfoStore.SList do begin
			if (LInfo.OperationCategory = LOC) then
				TOperationInfoStore.SMap[LOC].Add(LInfo.OperatorName, LInfo);
		end;
	end;
end;

class destructor TOperationInfoStore.Destroy();
var
	LInfo: TOperationInfo;
	LOC: TOperationCategory;
begin
	for LInfo in TOperationInfoStore.SList do
		LInfo.Free;

	for LOC in TOperationCategory do
		TOperationInfoStore.SMap[LOC].Free;
end;

constructor TFullOperationInfo.Create(AOperatorName: TOperatorName; ARunner: TOperationRunner;
	OC: TOperationCategory; APriority: Byte);
begin
	inherited Create(AOperatorName, OC, APriority);
	FRunner := ARunner;
end;

end.

