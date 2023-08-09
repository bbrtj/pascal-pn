unit PNStack;

{$mode objfpc}{$H+}{$J-}

{
	Stack implementation, the main data structure used by PN
}

interface

uses
	StrUtils, SysUtils, Contnrs,
	PNBase;

type

	TPNBaseStack = class abstract(TStack)
	public
		destructor Destroy; override;
		function Empty(): Boolean;
	end;

	TPNStack = class(TPNBaseStack)
	public
		const
			cSeparatorChar = '#';
			cInfixOperatorPrefixChar = 'o';
			cPrefixOperatorPrefixChar = 'p';
			cVariablePrefixChar = 'v';

		procedure Push(vItem: TItem);
		function Pop(): TItem;
		function Top(): TItem;
		procedure Clear();

		function ToString(): String; override;
		class function FromString(const vInput: String): TPNStack;
	end;

	TPNNumberStack = class(TPNBaseStack)
	public
		procedure Push(vItem: TNumber);
		function Pop(): TNumber;
		function Top(): TNumber;
	end;

implementation

destructor TPNBaseStack.Destroy;
var
	vRes: ^TItem;
begin
	while not self.Empty do begin
		vRes := self.Pop;
		Dispose(vRes);
	end;

	inherited;
end;

{ Checks whether the stack is empty }
function TPNBaseStack.Empty(): Boolean;
begin
	result := not self.AtLeast(1);
end;

{ Pushes on top of the stack }
procedure TPNStack.Push(vItem: TItem);
var
	vRes: ^TItem;
begin
	New(vRes);
	vRes^ := vItem;
	inherited Push(vRes);
end;

{ Pops the top of the stack }
function TPNStack.Pop(): TItem;
var
	vRes: ^TItem;
begin
	vRes := inherited Pop();
	result := TItem(vRes^);
	Dispose(vRes);
end;

{ Returns the top of the stack without poping it }
function TPNStack.Top(): TItem;
var
	vRes: ^TItem;
begin
	vRes := self.Peek();
	result := TItem(vRes^);
end;

procedure TPNStack.Clear();
begin
	while not self.Empty() do
		self.Pop();
end;

{ Exports to string, destroys the stack in the process }
function TPNStack.ToString(): String;
var
	vItem: TItem;
	vItemString: String;

begin
	result := '';
	while not self.Empty() do begin
		vItem := self.Pop();

		case vItem.ItemType of
			itNumber: vItemString := FloatToStr(vItem.Number);
			itVariable: vItemString := cVariablePrefixChar + vItem.VariableName;
			itOperator: begin
				case vItem.Operation.OperationCategory of
					ocInfix: vItemString := cInfixOperatorPrefixChar + vItem.Operation.OperatorName;
					ocPrefix: vItemString := cPrefixOperatorPrefixChar + vItem.Operation.OperatorName;
				end;
			end;
		end;

		result := vItemString + result;

		if not self.Empty() then
			result := cSeparatorChar + result;
	end;
end;

{ Imports from string, allocates a new object }
class function TPNStack.FromString(const vInput: String): TPNStack;
var
	vStack: TPNStack;
	vSplit: Array of String;
	vPart: String;

	function SkipFirstChar(): String;
	begin
		result := Copy(vPart, 2, Length(vPart));
	end;

begin
	vStack := TPNStack.Create;
	vSplit := SplitString(vInput, cSeparatorChar);


	for vPart in vSplit do begin

		if StartsStr(cVariablePrefixChar, vPart) then
			vStack.Push(MakeItem(TVariableName(SkipFirstChar())))

		else if StartsStr(cInfixOperatorPrefixChar, vPart) then
			vStack.Push(MakeItem(TOperatorName(SkipFirstChar()), ocInfix))

		else if StartsStr(cPrefixOperatorPrefixChar, vPart) then
			vStack.Push(MakeItem(TOperatorName(SkipFirstChar()), ocPrefix))

		else
			vStack.Push(MakeItem(StrToFloat(vPart)));
	end;

	result := vStack;
end;

{ Pushes on top of the stack }
procedure TPNNumberStack.Push(vItem: TNumber);
var
	vRes: ^TNumber;
begin
	New(vRes);
	vRes^ := vItem;
	inherited Push(vRes);
end;

{ Pops the top of the stack }
function TPNNumberStack.Pop(): TNumber;
var
	vRes: ^TNumber;
begin
	vRes := inherited Pop();
	result := TNumber(vRes^);
	Dispose(vRes);
end;

{ Returns the top of the stack without poping it }
function TPNNumberStack.Top(): TNumber;
var
	vRes: ^TNumber;
begin
	vRes := self.Peek();
	result := TNumber(vRes^);
end;

end.

