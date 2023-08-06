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
	TOperationType = (otSeparator, otMinus, otAddition, otSubtraction, otMultiplication, otDivision, otPower, otModulo, otLog, otLogN);

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

		class var
			SList: TOperationInfos;

	public
		constructor Create(vName: TOperatorName; vOT: TOperationType; vOC: TOperationCategory; vPriority: Byte);

		class function Find(const vName: TOperatorName; vOT: TOperationCategory): TOperationInfo;
		class function Check(const vName: TOperatorName): Boolean;
		class function LongestSymbolic(vOC: TOperationCategory): Byte;

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

function MakeItem(vValue: TNumber): TItem;
function MakeItem(const vValue: String): TItem;
function MakeItem(const vValue: TVariableName): TItem;
function MakeItem(const vValue: TOperatorName; vOT: TOperationCategory): TItem;
function MakeItem(vOperation: TOperationInfo): TItem;
function GetItemValue(vItem: TItem): String;

implementation

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

class function TOperationInfo.Find(const vName: TOperatorName; vOT: TOperationCategory): TOperationInfo;
var
	vInfo: TOperationInfo;
begin
	result := nil;
	for vInfo in SList do begin
		if (vInfo.FOperationCategory = vOT) and (vInfo.FOperatorName = vName) then
			exit(vInfo);
	end;
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

var
	vInfo: TOperationInfo;
initialization
	TOperationInfo.SList := [
		TOperationInfo.Create(',',     otSeparator,       ocInfix,   5),
		TOperationInfo.Create('+',     otAddition,        ocInfix,   10),
		TOperationInfo.Create('-',     otSubtraction,     ocInfix,   10),
		TOperationInfo.Create('*',     otMultiplication,  ocInfix,   20),
		TOperationInfo.Create('/',     otDivision,        ocInfix,   20),
		TOperationInfo.Create('%',     otModulo,          ocInfix,   20),
		TOperationInfo.Create('mod',   otModulo,          ocInfix,   20),
		TOperationInfo.Create('^',     otPower,           ocInfix,   30),
		TOperationInfo.Create('**',    otPower,           ocInfix,   30),
		TOperationInfo.Create('ln',    otLogN,            ocPrefix,  110),
		TOperationInfo.Create('log',   otLog,             ocPrefix,  110),
		TOperationInfo.Create('-',     otMinus,           ocPrefix,  255)
	];

finalization
	for vInfo in TOperationInfo.SList do
		vInfo.Free;

end.
