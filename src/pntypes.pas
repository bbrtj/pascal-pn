unit PNTypes;

{$mode objfpc}{$H+}{$J-}

interface

{
	Base types used by the Polish Notation implementation
}

type
	TNumber = Double;
	TVariable = String[10];
	TOperator = String[3];

	TVariableAssignment = packed record
		variable: TVariable;
		number: TNumber;
	end;

	TVariableMap = Array of TVariableAssignment;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = packed record
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

function MakeVariableAssignment(const variable: TVariable; const number: TNumber): TVariableAssignment;
begin
	result.variable := variable;
	result.number := number;
end;

function MakeItem(const value: TNumber): TItem;
begin
	result.itemType := itNumber;
	result.number := value;
end;

function MakeItem(const value: TVariable): TItem;
begin
	result.itemType := itVariable;
	result.variable := value;
end;

function MakeItem(const value: TOperator): TItem;
begin
	result.itemType := itOperator;
	result.&operator := value;
end;

end.
