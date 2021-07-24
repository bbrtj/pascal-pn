unit PNStack;

{$mode objfpc}{$H+}{$J-}

{
	Stack implementation, the main data structure used by PN
}

interface

uses
	StrUtils, SysUtils, Contnrs,
	PNTypes;

type

	TPNStack = class(TStack)
		public
			const
				separatorChar = '#';
				operatorPrefixChar = 'o';
				variablePrefixChar = 'v';

			destructor Destroy; override;

			procedure Push(const item: TItem);
			function Pop(): TItem;
			function Top(): TItem;

			function Empty(): Boolean;
			procedure Clear();

			function ToString(): String; override;
			class function FromString(const input: String): TPNStack;
	end;

implementation

{}
destructor TPNStack.Destroy;
begin
	Clear();
	inherited;
end;

{ Pushes on top of the stack }
procedure TPNStack.Push(const item: TItem);
var
	res: ^TItem;
begin
	New(res);
	res^ := item;
	inherited Push(res);
end;

{ Pops the top of the stack }
function TPNStack.Pop(): TItem;
var
	res: ^TItem;
begin
	res := inherited Pop();
	result := TItem(res^);
	Dispose(res);
end;

{ Returns the top of the stack without poping it }
function TPNStack.Top(): TItem;
var
	res: ^TItem;
begin
	res := Peek();
	result := TItem(res^);
end;

{ Checks whether the stack is empty }
function TPNStack.Empty(): Boolean;
begin
	result := not AtLeast(1);
end;

procedure TPNStack.Clear();
begin
	while not Empty() do
		Pop();
end;

{ Exports to string, destroys the stack in the process }
function TPNStack.ToString(): String;
var
	item: TItem;
	itemString: String;

begin
	result := '';
	while not Empty() do begin
		item := Pop();

		case item.itemtype of
			itNumber: itemString := FloatToStr(item.number);
			itVariable: itemString := variablePrefixChar + item.variable;
			itOperator: itemString := operatorPrefixChar + item.&operator;
		end;

		result := itemString + result;

		if not Empty() then
			result := separatorChar + result;
	end;
end;

{ Imports from string, allocates a new object }
class function TPNStack.FromString(const input: String): TPNStack;
var
	stack: TPNStack;

	split: Array of String;
	part: String;

	function SkipFirstChar(): String;
	begin
		result := Copy(part, 2, Length(part));
	end;

begin
	stack := TPNStack.Create;
	split := SplitString(input, separatorChar);


	for part in split do begin

		if StartsStr(variablePrefixChar, part) then
			stack.Push(MakeItem(TVariable(SkipFirstChar())))

		else if StartsStr(operatorPrefixChar, part) then
			stack.Push(MakeItem(TOperator(SkipFirstChar())))

		else
			stack.Push(MakeItem(StrToFloat(part)));
	end;

	result := stack;
end;

end.
