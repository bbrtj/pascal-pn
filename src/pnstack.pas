unit PNStack;

{$mode objfpc}{$H+}{$J-}

interface

uses
	StrUtils, SysUtils,
	PNTypes;

type

	PStackItem = ^TStackItem;
	TStackItem = packed record
		value: TItem;
		next: PStackItem;
	end;

	TPNStack = class
		protected
			stackHead: PStackItem;

		public
			const
				separatorChar = '#';
				operatorPrefixChar = '+';
				variablePrefixChar = '$';

			constructor Create;

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
constructor TPNStack.Create;
begin
	stackHead := nil;
end;

{ Pushes on top of the stack }
procedure TPNStack.Push(const item: TItem);
var
	stackItem: TStackItem;

begin
	stackItem.value := item;
	stackItem.next := stackHead;

	New(stackHead);
	stackHead^ := stackItem;
end;

{ Pops the top of the stack }
function TPNStack.Pop(): TItem;
var
	stackItem: TStackItem;

begin
	if self.Empty() then
		raise Exception.Create('Stack is empty');

	stackItem := stackHead^;
	Dispose(stackHead);

	stackHead := stackItem.next;
	result := stackItem.value;
end;

{ Returns the top of the stack without poping it }
function TPNStack.Top(): TItem;
begin
	if self.Empty() then
		raise Exception.Create('Stack is empty');

	result := stackHead^.value;
end;

{ Checks whether the stack is empty }
function TPNStack.Empty(): Boolean;
begin
	result := stackHead = nil;
end;

{ Clears the stack }
procedure TPNStack.Clear();
var
	nextStackHead: PStackItem;

begin
	while stackHead <> nil do begin
		nextStackHead := stackHead^.next;
		Dispose(stackHead);
		stackHead := nextStackHead;
	end;
end;

{ Exports to string, destroys the stack in the process }
function TPNStack.ToString(): String;
var
	item: TItem;
	itemString: String;

begin
	result := '';
	while not self.Empty() do begin
		item := self.Pop();

		case item.itemtype of
			itNumber: itemString := FloatToStr(item.number);
			itVariable: itemString := item.variable;
			itOperator: itemString := item.&operator;
		end;

		result := itemString + separatorChar + result;
	end;
end;

{ Imports from string, allocates a new object }
class function TPNStack.FromString(const input: String): TPNStack;
var
	stack: TPNStack;

	split: Array of String;
	part: String;

	valValue: TNumber;
	valCode: Word;

begin
	stack := TPNStack.Create;
	split := SplitString(input, separatorChar);

	for part in split do begin

		if StartsStr(variablePrefixChar, part) then
			stack.Push(MakeItem(TVariable(part)))

		else if StartsStr(operatorPrefixChar, part) then
			stack.Push(MakeItem(TOperator(Copy(part, 2, Length(part)))))

		else begin
			Val(part, valValue, valCode);

			if valCode = 0 then
				stack.Push(MakeItem(valValue))
			else
				raise Exception.Create('Data corrupted: not a number (' + part + ')');
		end;
	end;

	result := stack;
end;

end.
