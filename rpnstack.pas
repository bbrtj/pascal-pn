unit RPNStack;

{$mode objfpc}{$H+}{$J-}

interface

uses
	RPNTypes;

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
			procedure Push(item: TItem);
			function Pop(): TItem;
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
	stackItem := stackHead^;
	stackHead := stackItem.next;

	result := stackItem.value;
end;

end.
