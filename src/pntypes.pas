unit PNTypes;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

type
	TNumber = Double;
	TVariable = String[10];
	TOperator = String[3];

	TVariableAssignment = record
		variable: TVariable;
		number: TNumber;
	end;

	TVariableMap = Array of TVariableAssignment;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = record
		case itemType: TItemType of
			itNumber: (number: TNumber);
			itVariable: (variable: TVariable);
			itOperator: (&operator: TOperator);
	end;

function MakeVariableAssignment(const variable: TVariable; const number: TNumber): TVariableAssignment;
function MakeItem(const value: TNumber): TItem;
function MakeItem(const value: TVariable): TItem;
function MakeItem(const value: TOperator): TItem;

implementation

{ Creates TVariableAssignment }
function MakeVariableAssignment(const variable: TVariable; const number: TNumber): TVariableAssignment;
begin
	result.variable := variable;
	result.number := number;
end;

{ Creates TItem from TNumber }
function MakeItem(const value: TNumber): TItem;
begin
	result.itemType := itNumber;
	result.number := value;
end;

{ Creates TItem from TVariable }
function MakeItem(const value: TVariable): TItem;
begin
	result.itemType := itVariable;
	result.variable := value;
end;

{ Creates TItem from TOperator }
function MakeItem(const value: TOperator): TItem;
begin
	result.itemType := itOperator;
	result.&operator := value;
end;

end.
