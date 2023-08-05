unit PNBase;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl, SysUtils;

const
	cMaxPriority = 256;

type
	TNumber = Double;
	TVariable = String[20];
	TOperatorName = String[10];

	TVariableMap = specialize TFPGMap<TVariable, TNumber>;

	TOperationCategory = (ocPrefix, ocInfix);
	TOperationType = (otMinus, otAddition, otSubtraction, otMultiplication, otDivision, otPower, otModulo);
	TOperationInfo = record
		OperatorName: TOperatorName;
		Priority: UInt16;
		OperationType: TOperationType;
		OperationCategory: TOperationCategory;
	end;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = record
		case ItemType: TItemType of
			itNumber: (Number: TNumber);
			itVariable: (VariableName: TVariable);
			itOperator: (Operation: TOperationInfo);
	end;

function MakeItem(vValue: TNumber): TItem;
function MakeItem(const vValue: String): TItem;
function MakeItem(const vValue: TVariable): TItem;
function MakeItem(const vValue: TOperatorName): TItem;
function GetItemValue(vItem: TItem): String;

implementation

{ Creates TItem from TNumber }
function MakeItem(vValue: TNumber): TItem;
begin
	result.ItemType := itNumber;
	result.Number := vValue;
end;

{ Creates TItem from TVariable }
function MakeItem(const vValue: TVariable): TItem;
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
		result := MakeItem(TVariable(vValue))
	else
		raise Exception.Create('Invalid token ' + vValue);
end;

{ Creates TItem from TOperatorName }
function MakeItem(const vValue: TOperatorName): TItem;
begin
	result.ItemType := itOperator;
	result.OperatorName := vValue;
end;

function GetItemValue(vItem: TItem): String;
begin
	case vItem.ItemType of
		itNumber: result := String(vItem.Number);
		itVariable: result := vItem.VariableName;
		itOperator: result := vItem.OperatorName;
	end;
end;

end.

