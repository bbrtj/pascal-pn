unit PNBase;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl, SysUtils;

type
	TNumber = Double;
	TVariableName = type String[20];
	TOperatorName = type String[20];

	TVariableMap = specialize TFPGMap<TVariableName, TNumber>;

	TOperationCategory = (ocPrefix, ocInfix);
	TOperationType = (otMinus, otAddition, otSubtraction, otMultiplication, otDivision, otPower, otModulo);

	TOperationInfo = class
	strict private
		FOperatorName: TOperatorName;
		FPriority: Byte;
		FOperationType: TOperationType;
		FOperationCategory: TOperationCategory;

	private
		type
			TOperationInfos = Array of TOperationInfo;

		class var
			SList: TOperationInfos;

	public
		constructor Create(vName: TOperatorName; vOT: TOperationType; vOC: TOperationCategory; vPriority: Byte);

		class function Find(const vName: TOperatorName; vOT: TOperationCategory): TOperationInfo;
		class function Longest(vOC: TOperationCategory): Byte;

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
begin
	FOperatorName := vName;
	FOperationType := vOT;
	FOperationCategory := vOC;
	FPriority := vPriority;
end;

class function TOperationInfo.Find(const vName: TOperatorName; vOT: TOperationCategory): TOperationInfo;
var
	vInfo: TOperationInfo;
begin
	result := nil;
	for vInfo in SList do begin
		if (vInfo.OperationCategory = vOT) and (vInfo.OperatorName = vName) then
			exit(vInfo);
	end;
end;

class function TOperationInfo.Longest(vOC: TOperationCategory): Byte;
var
	vInfo: TOperationInfo;
begin
	result := 0;
	for vInfo in SList do begin
		if (vInfo.OperationCategory = vOC) and (length(vInfo.FOperatorName) > result) then
			result := length(vInfo.FOperatorName);
	end;
end;

initialization
	TOperationInfo.SList := [
		TOperationInfo.Create('+',    otAddition,        ocInfix,   10),
		TOperationInfo.Create('-',    otSubtraction,     ocInfix,   10),
		TOperationInfo.Create('*',    otMultiplication,  ocInfix,   20),
		TOperationInfo.Create('/',    otDivision,        ocInfix,   20),
		TOperationInfo.Create('%',    otModulo,          ocInfix,   20),
		TOperationInfo.Create('mod',  otModulo,          ocInfix,   20),
		TOperationInfo.Create('^',    otPower,           ocInfix,   30),
		TOperationInfo.Create('**',   otPower,           ocInfix,   30),
		TOperationInfo.Create('-',    otMinus,           ocPrefix,  255)
	];

// var
// 	vInfo: TOperationInfo;
// finalization
// 	for vInfo in TOperationInfo.SList do
// 		vInfo.Free;

end.

