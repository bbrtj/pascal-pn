unit RPNTypes;

{$mode objfpc}{$H+}{$J-}

interface

uses
	fgl;

type
	TNumber = Double;
	TVariable = String[15];
	TVariableMap = specialize TFPGMap<TVariable, TNumber>;

	TItemType = (Constant, Variable);
	TItem = packed record
		case itemType: TItemType of
			Constant: (number: TNumber);
			Variable: (variable: TVariable);
	end;

implementation

end.
