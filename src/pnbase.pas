unit PNBase;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl, SysUtils, Character;

const
	cDecimalSeparator = '.';

type
	TNumber = Double;
	TVariableName = type String[20];
	TOperatorName = type String[20];

	TVariableMap = specialize TFPGMap<TVariableName, TNumber>;

	TOperationCategory = (ocPrefix, ocInfix);
	TOperationType = (
		otSeparator,    otMinus,           otAddition,
		otSubtraction,  otMultiplication,  otDivision,
		otPower,        otModulo,          otDiv,
		otSqrt,         otLog,             otLogN,
		otSin,          otCos,             otTan,
		otCot,          otArcSin,          otArcCos,
		otRand,         otMin,             otMax,
		otRound,        otFloor,           otCeil,
		otSign,         otAbs,             otFact,
		otExp
	);

	TOperationInfo = class
	strict private
		FOperatorName: TOperatorName;
		FPriority: Byte;
		FOperationType: TOperationType;
		FOperationCategory: TOperationCategory;
		FSymbolic: Boolean;

	private
		type
			TOperationInfos = Array of TOperationInfo;
			TOperationMap = specialize TFPGMap<TOperatorName, TOperationInfo>;
			TOperationInfoMap = Array [TOperationCategory] of TOperationMap;

		class var
			SList: TOperationInfos;
			SMap: TOperationInfoMap;

	public
		constructor Create(OperatorName: TOperatorName; OT: TOperationType; OC: TOperationCategory; Priority: Byte);

		class function Find(const OperatorName: TOperatorName; OC: TOperationCategory): TOperationInfo;
		class function Check(const OperatorName: TOperatorName): Boolean;
		class function LongestSymbolic(OC: TOperationCategory): Byte;
		class function Help(Formatted: Boolean = True): String;

		property OperatorName: TOperatorName read FOperatorName;
		property Priority: Byte read FPriority;
		property OperationType: TOperationType read FOperationType;
		property OperationCategory: TOperationCategory read FOperationCategory;
	end;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = record
		case ItemType: TItemType of
			itNumber: (Number: TNumber);
			itVariable: (VariableName: TVariableName);
			itOperator: (Operation: TOperationInfo);
	end;

	ECalculationFailed = class(Exception);
	EInvalidExpression = class(ECalculationFailed);
	EUnknownVariable = class(ECalculationFailed);

	EParsingFailed = class(Exception);
	EInvalidStatement = class(EParsingFailed);
	EUnmatchedBraces = class(EParsingFailed);
	EInvalidVariableName = class(EParsingFailed);

function MakeItem(Value: TNumber): TItem;
function MakeItem(const Value: String): TItem;
function MakeItem(const Value: String; ItemType: TItemType): TItem;
function MakeItem(const Value: TVariableName): TItem;
function MakeItem(const Value: TOperatorName; OT: TOperationCategory): TItem;
function MakeItem(Operation: TOperationInfo): TItem;
function GetItemValue(const Item: TItem): String;

implementation

const
	cOperationTypeDesc: Array[otSeparator .. otExp] of String = (
		{ otSeparator } 'separates multiple values for function calls',
		{ otMinus } 'unary minus, yielding opposite number',
		{ otAddition } 'addition, a plus b',
		{ otSubtraction } 'subtraction, a minus b',
		{ otMultiplication } 'multiplication, a times b',
		{ otDivision } 'division, a divided by b',
		{ otPower } 'power, a to the power of b',
		{ otModulo } 'modulo, the remainder of a divided by b',
		{ otDiv } 'integer division, division without fraction',
		{ otSqrt } 'f(x), square root of x',
		{ otLog } 'f(x), natural logarithm of x (E-based)',
		{ otLogN } 'f(x, y), x-based logarithm of y',
		{ otSin } 'f(x), sinus of x',
		{ otCos } 'f(x), cosinus of x',
		{ otTan } 'f(x), tangent of x',
		{ otCot } 'f(x), cotangent of x',
		{ otArcSin } 'f(x), arcus sinus of x',
		{ otArcCos } 'f(x), arcus cosinus of x',
		{ otRand } 'f(x), random integer from 0 to x - 1',
		{ otMin } 'f(x, y), smaller of two values',
		{ otMax } 'f(x, y), larger of two values',
		{ otRound } 'f(x), rounds x to the nearest integer',
		{ otFloor } 'f(x), rounds x to the nearest smaller integer',
		{ otCeil } 'f(x), rounds x to the nearest larger integer',
		{ otSign } 'f(x), returns 1, 0 or -1 for positive, zero or negative x',
		{ otAbs } 'f(x), returns absolute value of x',
		{ otFact } 'f(x), returns factorial of x',
		{ otExp } 'f(x), returns exponent of x'
	);

var
	GFloatFormat: TFormatSettings;

{ Creates TItem from TNumber }
function MakeItem(Value: TNumber): TItem;
begin
	result.ItemType := itNumber;
	result.Number := Value;
end;

{ Creates TItem from TVariableName }
function MakeItem(const Value: TVariableName): TItem;
begin
	result.ItemType := itVariable;
	result.VariableName := Value;
end;

{ Creates TItem from a string (guess) }
function MakeItem(const Value: String): TItem;
var
	LNumericValue: TNumber;
begin
	if TryStrToFloat(Value, LNumericValue, GFloatFormat) then
		result := MakeItem(LNumericValue)
	else if IsValidIdent(Value) then
		result := MakeItem(TVariableName(Value))
	else
		raise Exception.Create('Invalid token ' + Value);
end;

{ Creates TItem from a string (guess and check) }
function MakeItem(const Value: String; ItemType: TItemType): TItem;
begin
	result := MakeItem(Value);
	if result.ItemType <> ItemType then
		raise Exception.Create('Invalid token ' + Value);
end;

{ Creates TItem from TOperatorName }
function MakeItem(const Value: TOperatorName; OT: TOperationCategory): TItem;
begin
	result.ItemType := itOperator;
	result.Operation := TOperationInfo.Find(Value, OT);

	if result.Operation = nil then
		raise Exception.Create('Invalid token ' + Value);
end;

{ creates TItem from TOperationInfo }
function MakeItem(Operation: TOperationInfo): TItem;
begin
	result.ItemType := itOperator;
	result.Operation := Operation;
end;

function GetItemValue(const Item: TItem): String;
begin
	case Item.ItemType of
		itNumber: result := FloatToStr(Item.Number, GFloatFormat);
		itVariable: result := Item.VariableName;
		itOperator: result := Item.Operation.OperatorName;
	end;
end;

constructor TOperationInfo.Create(OperatorName: TOperatorName; OT: TOperationType; OC: TOperationCategory; Priority: Byte);
var
	LChar: Char;
begin
	FOperatorName := OperatorName;
	FOperationType := OT;
	FOperationCategory := OC;
	FPriority := Priority;

	FSymbolic := True;
	for LChar in OperatorName do begin
		if IsLetterOrDigit(LChar) or (LChar = '_') then begin
			FSymbolic := False;
			break;
		end;
	end;
end;

class function TOperationInfo.Find(const OperatorName: TOperatorName; OC: TOperationCategory): TOperationInfo;
var
	LFound: Integer;
begin
	if SMap[OC].Find(OperatorName, LFound) then
		result := SMap[OC].Data[LFound]
	else
		result := nil;
end;

class function TOperationInfo.Check(const OperatorName: TOperatorName): Boolean;
var
	LInfo: TOperationInfo;
begin
	result := False;
	for LInfo in SList do begin
		if LInfo.FOperatorName = OperatorName then
			exit(True);
	end;
end;

class function TOperationInfo.LongestSymbolic(OC: TOperationCategory): Byte;
var
	LInfo: TOperationInfo;
begin
	result := 0;
	for LInfo in SList do begin
		if LInfo.FSymbolic and (LInfo.FOperationCategory = OC) and (length(LInfo.FOperatorName) > result) then
			result := length(LInfo.FOperatorName);
	end;
end;

class function TOperationInfo.Help(Formatted: Boolean = True): String;
var
	LInfo: TOperationInfo;
	LLongest: Byte;
begin
	LLongest := 0;
	for LInfo in SList do begin
		if length(LInfo.OperatorName) > LLongest then
			LLongest := length(LInfo.OperatorName);
	end;

	result := '';
	for LInfo in SList do begin
		if Formatted then
			result += Format('[ %-' + IntToStr(LLongest) + 's ]: ', [LInfo.OperatorName])
		else
			result += LInfo.OperatorName + ': ';

		result += cOperationTypeDesc[LInfo.OperationType] + sLineBreak;
	end;
end;

var
	GInfo: TOperationInfo;
	GOC: TOperationCategory;
initialization
	GFloatFormat.DecimalSeparator := cDecimalSeparator;

	TOperationInfo.SList := [
		TOperationInfo.Create(',',       otSeparator,       ocInfix,   5),
		TOperationInfo.Create('+',       otAddition,        ocInfix,   10),
		TOperationInfo.Create('-',       otSubtraction,     ocInfix,   10),
		TOperationInfo.Create('*',       otMultiplication,  ocInfix,   20),
		TOperationInfo.Create('/',       otDivision,        ocInfix,   20),
		TOperationInfo.Create('%',       otModulo,          ocInfix,   20),
		TOperationInfo.Create('mod',     otModulo,          ocInfix,   20),
		TOperationInfo.Create('//',      otDiv,             ocInfix,   20),
		TOperationInfo.Create('div',     otDiv,             ocInfix,   20),
		TOperationInfo.Create('^',       otPower,           ocInfix,   30),
		TOperationInfo.Create('**',      otPower,           ocInfix,   30),

		TOperationInfo.Create('sqrt',    otSqrt,            ocPrefix,  2),
		TOperationInfo.Create('ln',      otLogN,            ocPrefix,  2),
		TOperationInfo.Create('log',     otLog,             ocPrefix,  2),
		TOperationInfo.Create('sin',     otSin,             ocPrefix,  2),
		TOperationInfo.Create('cos',     otCos,             ocPrefix,  2),
		TOperationInfo.Create('tan',     otTan,             ocPrefix,  2),
		TOperationInfo.Create('cot',     otCot,             ocPrefix,  2),
		TOperationInfo.Create('arcsin',  otArcSin,          ocPrefix,  2),
		TOperationInfo.Create('arccos',  otArcCos,          ocPrefix,  2),
		TOperationInfo.Create('rand',    otRand,            ocPrefix,  2),
		TOperationInfo.Create('min',     otMin,             ocPrefix,  2),
		TOperationInfo.Create('max',     otMax,             ocPrefix,  2),
		TOperationInfo.Create('round',   otRound,           ocPrefix,  2),
		TOperationInfo.Create('floor',   otFloor,           ocPrefix,  2),
		TOperationInfo.Create('ceil',    otCeil,            ocPrefix,  2),
		TOperationInfo.Create('sign',    otSign,            ocPrefix,  2),
		TOperationInfo.Create('abs',     otAbs,             ocPrefix,  2),
		TOperationInfo.Create('fact',    otFact,            ocPrefix,  2),
		TOperationInfo.Create('exp',     otExp,             ocPrefix,  2),
		TOperationInfo.Create('-',       otMinus,           ocPrefix,  255)
	];

	for GOC in TOperationCategory do begin
		TOperationInfo.SMap[GOC] := TOperationInfo.TOperationMap.Create;
		TOperationInfo.SMap[GOC].Sorted := True;
		for GInfo in TOperationInfo.SList do begin
			if (GInfo.OperationCategory = GOC) then
				TOperationInfo.SMap[GOC].Add(GInfo.OperatorName, GInfo);
		end;
	end;

finalization
	for GInfo in TOperationInfo.SList do
		GInfo.Free;

	for GOC in TOperationCategory do
		TOperationInfo.SMap[GOC].Free;


end.

