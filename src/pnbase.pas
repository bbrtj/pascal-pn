unit PNBase;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl, SysUtils, Character;

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
		constructor Create(vName: TOperatorName; vOT: TOperationType; vOC: TOperationCategory; vPriority: Byte);

		class function Find(const vName: TOperatorName; vOC: TOperationCategory): TOperationInfo;
		class function Check(const vName: TOperatorName): Boolean;
		class function LongestSymbolic(vOC: TOperationCategory): Byte;
		class function Help(vFormatted: Boolean = True): String;

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

	EParsingFailed = class(Exception);
	EInvalidStatement = class(EParsingFailed);
	EUnmatchedBraces = class(EParsingFailed);
	EInvalidVariableName = class(EParsingFailed);

function MakeItem(vValue: TNumber): TItem;
function MakeItem(const vValue: String): TItem;
function MakeItem(const vValue: TVariableName): TItem;
function MakeItem(const vValue: TOperatorName; vOT: TOperationCategory): TItem;
function MakeItem(vOperation: TOperationInfo): TItem;
function GetItemValue(vItem: TItem): String;

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

{ Creates TItem from TNumber }
function MakeItem(vValue: TNumber): TItem;
begin
	result.ItemType := itNumber;
	result.Number := vValue;
end;

{ Creates TItem from TVariableName }
function MakeItem(const vValue: TVariableName): TItem;
begin
	result.ItemType := itVariable;
	result.VariableName := vValue;
end;

{ Creates TItem from a string (guess) }
function MakeItem(const vValue: String): TItem;
var
	vNumericValue: TNumber;
begin
	if TryStrToFloat(vValue, vNumericValue) then
		result := MakeItem(vNumericValue)
	else if IsValidIdent(vValue) then
		result := MakeItem(TVariableName(vValue))
	else
		raise Exception.Create('Invalid token ' + vValue);
end;

{ Creates TItem from TOperatorName }
function MakeItem(const vValue: TOperatorName; vOT: TOperationCategory): TItem;
begin
	result.ItemType := itOperator;
	result.Operation := TOperationInfo.Find(vValue, vOT);

	if result.Operation = nil then
		raise Exception.Create('Invalid token ' + vValue);
end;

{ creates TItem from TOperationInfo }
function MakeItem(vOperation: TOperationInfo): TItem;
begin
	result.ItemType := itOperator;
	result.Operation := vOperation;
end;

function GetItemValue(vItem: TItem): String;
begin
	case vItem.ItemType of
		itNumber: result := String(vItem.Number);
		itVariable: result := vItem.VariableName;
		itOperator: result := vItem.Operation.OperatorName;
	end;
end;

constructor TOperationInfo.Create(vName: TOperatorName; vOT: TOperationType; vOC: TOperationCategory; vPriority: Byte);
var
	vChar: Char;
begin
	FOperatorName := vName;
	FOperationType := vOT;
	FOperationCategory := vOC;
	FPriority := vPriority;

	FSymbolic := True;
	for vChar in vName do begin
		if IsLetterOrDigit(vChar) or (vChar = '_') then begin
			FSymbolic := False;
			break;
		end;
	end;
end;

class function TOperationInfo.Find(const vName: TOperatorName; vOC: TOperationCategory): TOperationInfo;
var
	vFound: Integer;
begin
	if SMap[vOC].Find(vName, vFound) then
		result := SMap[vOC].Data[vFound]
	else
		result := nil;
end;

class function TOperationInfo.Check(const vName: TOperatorName): Boolean;
var
	vInfo: TOperationInfo;
begin
	result := False;
	for vInfo in SList do begin
		if vInfo.FOperatorName = vName then
			exit(True);
	end;
end;

class function TOperationInfo.LongestSymbolic(vOC: TOperationCategory): Byte;
var
	vInfo: TOperationInfo;
begin
	result := 0;
	for vInfo in SList do begin
		if vInfo.FSymbolic and (vInfo.FOperationCategory = vOC) and (length(vInfo.FOperatorName) > result) then
			result := length(vInfo.FOperatorName);
	end;
end;

class function TOperationInfo.Help(vFormatted: Boolean = True): String;
var
	vInfo: TOperationInfo;
	vLongest: Byte;
begin
	vLongest := 0;
	for vInfo in SList do begin
		if length(vInfo.OperatorName) > vLongest then
			vLongest := length(vInfo.OperatorName);
	end;

	result := '';
	for vInfo in SList do begin
		if vFormatted then
			result += Format('[ %-' + IntToStr(vLongest) + 's ]: ', [vInfo.OperatorName])
		else
			result += vInfo.OperatorName + ': ';

		result += cOperationTypeDesc[vInfo.OperationType] + sLineBreak;
	end;
end;

var
	vInfo: TOperationInfo;
	vOC: TOperationCategory;
initialization
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

	for vOC in TOperationCategory do begin
		TOperationInfo.SMap[vOC] := TOperationInfo.TOperationMap.Create;
		TOperationInfo.SMap[vOC].Sorted := True;
		for vInfo in TOperationInfo.SList do begin
			if (vInfo.OperationCategory = vOC) then
				TOperationInfo.SMap[vOC].Add(vInfo.OperatorName, vInfo);
		end;
	end;

finalization
	for vInfo in TOperationInfo.SList do
		vInfo.Free;

	for vOC in TOperationCategory do
		TOperationInfo.SMap[vOC].Free;


end.

