unit PNStack;

{$mode objfpc}{$H+}{$J-}

interface

uses
	StrUtils, PNTypes, SysUtils;

type

	PStackItem = ^TStackItem;
	TStackItem = packed record
		value: TItem;
		next: PStackItem;
	end;

	TStack = class
		protected
			stackHead: PStackItem;

		public
			const
				separatorChar = '#';
				operatorPrefixChar = '+';

			procedure Push(item: TItem);
			function Pop(): TItem;

			function Empty(): Boolean;
			procedure Clear();

			function ToString(): String;
			class function FromString(input: String): TStack;
	end;

implementation

procedure TStack.Push(item: TItem);
var
	stackItem: TStackItem;

begin
	stackItem.value := item;
	stackItem.next := stackHead;

	stackHead := @stackItem;
end;

function TStack.Pop(): TItem;
var
	stackItem: TStackItem;

begin
	if stackHead = nil then
		raise Exception.Create('Stack is empty');

	stackItem := stackHead^;
	stackHead := stackItem.next;
	result := stackItem.value;
end;

function TStack.Empty(): Boolean;
begin
	result := stackHead = nil;
end;

procedure TStack.Clear();
begin
	stackHead := nil;
end;

function TStack.ToString(): String;
var
	output: String;

begin
	output := '';
	result := output
end;

class function TStack.FromString(input: String): TStack;
var
	stack: TStack;
	item: TItem;

	split: Array of String;
	part: String;

	valValue: TNumber;
	valCode: Word;

begin
	stack := TStack.Create;
	split := SplitString(input, separatorChar);

	for part in split do begin
		Val(part, valValue, valCode);

		if valCode = 0 then begin
			item.itemType := itNumber;
			item.number := valValue;
		end
		else if StartsStr(operatorPrefixChar, part) then begin

			item.itemType := itOperator;
			item.&operator := Copy(part, 2, Length(part));
		end
		else begin
			item.itemType := itVariable;
			item.variable := part;
		end;

		stack.Push(item);
	end;

	result := stack;
end;

end.
