unit PNTypes;

{$mode objfpc}{$H+}{$J-}

{$define Operator := ClassOperator }

interface

uses
	fgl;

type
	TNumber = Double;
	TVariable = String[15];
	TOperator = String[15];
	TVariableMap = specialize TFPGMap<TVariable, TNumber>;

	TItemType = (itNumber, itVariable, itOperator);
	TItem = packed record
		case itemType: TItemType of
			itNumber: (number: TNumber);
			itVariable: (variable: TVariable);
			itOperator: (&operator: TOperator);
	end;

implementation

end.
