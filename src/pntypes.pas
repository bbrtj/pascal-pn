unit PNTypes;

{$mode objfpc}{$H+}{$J-}

{
	Base types used by the Polish Notation implementation
}

interface

uses
	Fgl;

type
	TNumber = Double;
	TVariable = String[10];
	TOperator = String[3];

	TVariableMap = specialize TFPGMap<TVariable, TNumber>;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = record
		case itemType: TItemType of
			itNumber: (number: TNumber);
			itVariable: (variable: TVariable);
			itOperator: (&operator: TOperator);
	end;

function MakeItem(const value: TNumber): TItem; inline;
function MakeItem(const value: TVariable): TItem; inline;
function MakeItem(const value: TOperator): TItem; inline;

implementation

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
