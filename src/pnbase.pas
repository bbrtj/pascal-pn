unit PNBase;

{$mode objfpc}{$H+}{$J-}

{$ifdef RELEASE}{$optimization autoinline}{$endif}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl, Math, SysUtils, Character;

const
	cDecimalSeparator = '.';

type
	TNumber = Extended;
	TVariableName = type String[20];
	TOperatorName = type String[20];

	TNumberList = Array of TNumber;
	PNumberList = ^TNumberList;

	TVariableMap = specialize TFPGMap<TVariableName, TNumber>;

	TOperationCategory = (ocPrefix, ocInfix);

	TOperationInfo = class
	strict private
		FOperatorName: TOperatorName;
		FPriority: Byte;
		FOperationCategory: TOperationCategory;
		FSymbolic: Boolean;
		FHelp: String;

	public
		constructor Create(AOperatorName: TOperatorName; OC: TOperationCategory; APriority: Byte);

		class function Find(const OperatorName: TOperatorName; OC: TOperationCategory): TOperationInfo;
		class function Check(const OperatorName: TOperatorName): Boolean;
		class function FullHelp(Formatted: Boolean = True): String;

		function WithHelp(const AHelp: String): TOperationInfo;

		property Help: String read FHelp write FHelp;
		property OperatorName: TOperatorName read FOperatorName;
		property Priority: Byte read FPriority;
		property OperationCategory: TOperationCategory read FOperationCategory;
	end;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = record
		ParsedAt: UInt32;
		case ItemType: TItemType of
			itNumber: (Number: TNumber);
			itVariable: (VariableName: TVariableName);
			itOperator: (Operation: TOperationInfo);
	end;

	TItemArray = Array of TItem;

	EPNException = class(Exception);
	ECalculationFailed = class(EPNException);
	EInvalidExpression = class(ECalculationFailed);
	ENotAggregated = class(ECalculationFailed);
	EStackError = class(ECalculationFailed);
	EUnknownVariable = class(ECalculationFailed);
	TCalculationFailedClass = class of ECalculationFailed;

	EParsingFailed = class(EPNException);
	EInvalidStatement = class(EParsingFailed);
	EUnmatchedBraces = class(EParsingFailed);
	EInvalidVariableName = class(EParsingFailed);
	TParsingFailedClass = class of EParsingFailed;

function MakeItem(Value: TNumber): TItem;
function MakeItem(const Value: String): TItem;
function MakeItem(const Value: TVariableName): TItem;
function MakeItem(const Value: TOperatorName; OT: TOperationCategory): TItem;
function MakeItem(Operation: TOperationInfo): TItem;

function GetItemValue(const Item: TItem): String;
function FastStrToFloat(const Txt: String; var Offset: UInt32): TNumber;

implementation

uses PNCalculator;

var
	GFloatFormat: TFormatSettings;

{ private, helper }
function CharToInt(const Digit: Char): Int8;
begin
	case Digit of
		'0': result := 0;
		'1': result := 1;
		'2': result := 2;
		'3': result := 3;
		'4': result := 4;
		'5': result := 5;
		'6': result := 6;
		'7': result := 7;
		'8': result := 8;
		'9': result := 9;
		'a', 'A': result := 10;
		'b', 'B': result := 11;
		'c', 'C': result := 12;
		'd', 'D': result := 13;
		'e', 'E': result := 14;
		'f', 'F': result := 15;
	else
		result := -1;
	end;
end;

{ private, helper }
function DigitsFromStr(const Txt: String; var Offset: UInt32; Base: UInt8 = 10): TNumber;
var
	I: UInt32;
	LDigit: Int8;
begin
	result := 0;

	for I := Offset to High(Txt) do begin
		LDigit := CharToInt(Txt[I]);
		if (LDigit < 0) or (LDigit >= Base) then break;

		result := result * Base + LDigit;
		Inc(Offset);
	end;
end;

type
	TParsedNumber = record
		Value: TNumber;
		Sign: Single;
		Base: UInt8;
	end;

{ private, helper }
function ParseNumber(const Txt: String; var Offset: UInt32): TParsedNumber;
var
	I, OldI: UInt32;
	LNegative: Boolean;
	LSize: UInt32;
begin
	I := Offset;
	LSize := High(Txt);

	if I > LSize then exit;

	LNegative := Txt[I] = '-';
	result.Sign := 1 - 2 * Ord(LNegative);
	if LNegative or (Txt[I] = '+') then
		Inc(I);

	result.Base := 10;
	if (I < LSize) and (Txt[I] = '0') then begin
		case Txt[I + 1] of
			'b': result.Base := 2;
			'o': result.Base := 8;
			'x': result.Base := 16;
		end;

		if result.Base <> 10 then
			Inc(I, 2);
	end;

	OldI := I;
	result.Value := DigitsFromStr(Txt, I, result.Base);
	if OldI = I then begin
		if result.Base = 10 then exit;

		// fall back to 0 before base letter, like 0 in 0x
		result.Base := 10;
		result.Value := 0;
	end;

	Offset := I;
end;

function FastStrToFloat(const Txt: String; var Offset: UInt32): TNumber;
var
	I, OldI: UInt32;
	LSize: UInt32;
	LSecondary: TNumber;
	LParsed: TParsedNumber;
begin
	LSize := High(Txt);
	I := Offset;

	// get the number
	OldI := I;
	LParsed := ParseNumber(Txt, I);
	if OldI = I then exit(0);

	result := LParsed.Value;

	// handle fraction
	if (I < LSize) and (Txt[I] = cDecimalSeparator) then begin
		Inc(I);
		OldI := I;
		LSecondary := DigitsFromStr(Txt, I, LParsed.Base);

		if OldI = I then I := OldI - 1
		else result := result + (LSecondary / Power(LParsed.Base, I - OldI));
	end;

	// handle sign here, since the number may be 0 with a fraction
	result *= LParsed.Sign;

	// handle the exponent (only for base 10!)
	if (I < LSize) and (LParsed.Base = 10) and ((Txt[I] = 'E') or (Txt[I] = 'e')) then begin
		Inc(I);
		OldI := I;
		LParsed := ParseNumber(Txt, I);

		if (OldI = I) or (LParsed.Base <> 10) then I := OldI - 1
		else result := result * Power(10, LParsed.Sign * LParsed.Value);
	end;

	Offset := I;
end;

{ Creates TItem from TNumber }
function MakeItem(Value: TNumber): TItem;
begin
	result.ParsedAt := 0;
	result.ItemType := itNumber;
	result.Number := Value;
end;

{ Creates TItem from TVariableName }
function MakeItem(const Value: TVariableName): TItem;
begin
	result.ParsedAt := 0;
	result.ItemType := itVariable;
	result.VariableName := Value;
end;

{ Creates TItem from a string (guess TNumber) }
function MakeItem(const Value: String): TItem;
var
	LOffset: UInt32;
begin
	LOffset := Low(Value);
	result := MakeItem(FastStrToFloat(Value, LOffset));
	if (Length(Value) = 0) or (LOffset <> High(Value) + 1) then
		raise Exception.Create('Could not convert the number');
end;

{ Creates TItem from TOperatorName }
function MakeItem(const Value: TOperatorName; OT: TOperationCategory): TItem;
begin
	result.ParsedAt := 0;
	result.ItemType := itOperator;
	result.Operation := TOperationInfo.Find(Value, OT);

	if result.Operation = nil then
		raise Exception.Create('Invalid token ' + Value);
end;

{ creates TItem from TOperationInfo }
function MakeItem(Operation: TOperationInfo): TItem;
begin
	result.ParsedAt := 0;
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

constructor TOperationInfo.Create(AOperatorName: TOperatorName; OC: TOperationCategory; APriority: Byte);
var
	LChar: Char;
begin
	FOperatorName := AOperatorName;
	FOperationCategory := OC;
	FPriority := APriority;

	FSymbolic := True;
	for LChar in AOperatorName do begin
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
	if TOperationInfoStore.SMap[OC].Find(OperatorName, LFound) then
		result := TOperationInfoStore.SMap[OC].Data[LFound]
	else
		result := nil;
end;

class function TOperationInfo.Check(const OperatorName: TOperatorName): Boolean;
var
	LInfo: TOperationInfo;
begin
	result := False;
	for LInfo in TOperationInfoStore.SList do begin
		if LInfo.FOperatorName = OperatorName then
			exit(True);
	end;
end;

class function TOperationInfo.FullHelp(Formatted: Boolean = True): String;
var
	LInfo: TOperationInfo;
	LLongest: Byte;
begin
	LLongest := 0;
	for LInfo in TOperationInfoStore.SList do begin
		if length(LInfo.OperatorName) > LLongest then
			LLongest := length(LInfo.OperatorName);
	end;

	result := '';
	for LInfo in TOperationInfoStore.SList do begin
		if Formatted then
			result += Format('[ %-' + IntToStr(LLongest) + 's ]: ', [LInfo.OperatorName])
		else
			result += LInfo.OperatorName + ': ';

		result += LInfo.Help + sLineBreak;
	end;
end;

{ helper for inline construction }
function TOperationInfo.WithHelp(const AHelp: String): TOperationInfo;
begin
	self.Help := AHelp;
	result := self;
end;

initialization
	GFloatFormat.DecimalSeparator := cDecimalSeparator;
end.

