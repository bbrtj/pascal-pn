unit PNStack;

{$mode objfpc}{$H+}{$J-}

{
	Stack implementation, the main data structure used by PN
}

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
				operatorPrefixChar = 'o';
				variablePrefixChar = 'v';

			constructor Create;
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
constructor TPNStack.Create;
begin
	stackHead := nil;
end;

{}
destructor TPNStack.Destroy;
begin
	Clear();
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
	if Empty() then
		raise Exception.Create('Stack is empty');

	stackItem := stackHead^;
	Dispose(stackHead);

	stackHead := stackItem.next;
	result := stackItem.value;
end;

{ Returns the top of the stack without poping it }
function TPNStack.Top(): TItem;
begin
	if Empty() then
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

	valValue: TNumber;
	valCode: Word;

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
