unit PNStack;

{$mode objfpc}{$H+}{$J-}
{$modeswitch advancedrecords}

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
		function Empty(): Boolean;
	end;

	TPNStack = class(TPNBaseStack)
	public
		const
			cSeparatorChar = '#';
			cInfixOperatorPrefixChar = 'o';
			cPrefixOperatorPrefixChar = 'p';
			cVariablePrefixChar = 'v';

		destructor Destroy; override;

		procedure Push(const Item: TItem);
		function Pop(): TItem;
		function Top(): TItem;
		procedure Clear();

		function ToString(): String; override;
		class function FromString(const InputString: String): TPNStack;
		function ToArray(): TItemArray;
	end;

	PNumberList = ^TNumberList;
	TNumberList = record
		Number: TNumber;
		NextNumber: PNumberList;

		class operator Initialize(var Rec: TNumberList);
		function Count(): UInt32;
		procedure Push(ANumber: TNumber);
		function Pop(): TNumber;
	end;

	TPNCalculationStack = class(TPNBaseStack)
	public
		destructor Destroy; override;

		procedure Push(Item: TNumber);
		procedure AddToTop(Item: TNumber);
		function PopList(): TNumberList;
		function Pop(): TNumber;
	end;

implementation

destructor TPNStack.Destroy;
var
	LRes: ^TItem;
begin
	while not self.Empty do begin
		LRes := inherited Pop;
		Dispose(LRes);
	end;

	inherited;
end;

{ Checks whether the stack is empty }
function TPNBaseStack.Empty(): Boolean;
begin
	result := not self.AtLeast(1);
end;

{ Pushes on top of the stack }
procedure TPNStack.Push(const Item: TItem);
var
	LRes: ^TItem;
begin
	New(LRes);
	LRes^ := Item;
	inherited Push(LRes);
end;

{ Pops the top of the stack }
function TPNStack.Pop(): TItem;
var
	LRes: ^TItem;
begin
	LRes := inherited Pop();
	result := TItem(LRes^);
	Dispose(LRes);
end;

{ Returns the top of the stack without poping it }
function TPNStack.Top(): TItem;
var
	LRes: ^TItem;
begin
	LRes := self.Peek();
	result := TItem(LRes^);
end;

procedure TPNStack.Clear();
begin
	while not self.Empty() do
		self.Pop();
end;

{ Exports to string, destroys the stack in the process }
function TPNStack.ToString(): String;
var
	LItem: TItem;
	LItemString: String;
begin
	result := '';
	while not self.Empty() do begin
		LItem := self.Pop();

		case LItem.ItemType of
			itNumber: LItemString := '';
			itVariable: LItemString := cVariablePrefixChar;
			itOperator: begin
				case LItem.Operation.OperationCategory of
					ocInfix: LItemString := cInfixOperatorPrefixChar;
					ocPrefix: LItemString := cPrefixOperatorPrefixChar;
				end;
			end;
		end;

		result := LItemString + GetItemValue(LItem) + result;

		if not self.Empty() then
			result := cSeparatorChar + result;
	end;
end;

{ Imports from string, allocates a new object }
class function TPNStack.FromString(const InputString: String): TPNStack;
var
	LStack: TPNStack;
	LSplit: Array of String;
	LPart: String;

	function SkipFirstChar(): String;
	begin
		result := Copy(LPart, 2, Length(LPart));
	end;

begin
	LStack := TPNStack.Create;
	LSplit := SplitString(InputString, cSeparatorChar);

	for LPart in LSplit do begin

		if StartsStr(cVariablePrefixChar, LPart) then
			LStack.Push(MakeItem(TVariableName(SkipFirstChar())))

		else if StartsStr(cInfixOperatorPrefixChar, LPart) then
			LStack.Push(MakeItem(TOperatorName(SkipFirstChar()), ocInfix))

		else if StartsStr(cPrefixOperatorPrefixChar, LPart) then
			LStack.Push(MakeItem(TOperatorName(SkipFirstChar()), ocPrefix))

		else
			LStack.Push(MakeItem(LPart));
	end;

	result := LStack;
end;

function TPNStack.ToArray(): TItemArray;
var
	I: Integer;
begin
	SetLength(result, self.Count);

	I := 0;
	while not self.Empty do begin
		result[I] := self.Pop;
		Inc(I);
	end;
end;

class operator TNumberList.Initialize(var Rec: TNumberList);
begin
	Rec.NextNumber := nil;
end;

function TNumberList.Count(): UInt32;
var
	LNext: PNumberList;
begin
	result := 1;
	LNext := self.NextNumber;
	while LNext <> nil do begin
		Inc(result);
		LNext := LNext^.NextNumber;
	end;
end;

procedure TNumberList.Push(ANumber: TNumber);
var
	LRes: PNumberList;
	LTop: PNumberList;
begin
	LTop := @self;
	while LTop^.NextNumber <> nil do
		LTop := LTop^.NextNumber;

	New(LRes);
	LRes^.Number := ANumber;
	LTop^.NextNumber := LRes;
end;

function TNumberList.Pop(): TNumber;
var
	LLast, LTop: PNumberList;
begin
	LLast := @self;
	LTop := self.NextNumber;
	while LTop^.NextNumber <> nil do begin
		LLast := LTop;
		LTop := LTop^.NextNumber;
	end;

	LLast^.NextNumber := nil;
	result := LTop^.Number;
	Dispose(LTop);
end;

destructor TPNCalculationStack.Destroy;
var
	LRes: TNumberList;
begin
	while not self.Empty do begin
		LRes := self.PopList;
		while LRes.Count > 1 do
			LRes.Pop;
	end;

	inherited;
end;

{ Pushes on top of the stack }
procedure TPNCalculationStack.Push(Item: TNumber);
var
	LRes: PNumberList;
begin
	New(LRes);
	LRes^.Number := Item;
	inherited Push(LRes);
end;

procedure TPNCalculationStack.AddToTop(Item: TNumber);
begin
	PNumberList(self.Peek)^.Push(Item);
end;

function TPNCalculationStack.PopList(): TNumberList;
var
	LRes: PNumberList;
begin
	LRes := PNumberList(inherited Pop());

	result := LRes^;
	Dispose(LRes);
end;

{ Pops the top of the stack }
function TPNCalculationStack.Pop(): TNumber;
var
	LRes: PNumberList;
begin
	LRes := PNumberList(inherited Pop());
	if LRes^.Count > 1 then begin
		inherited Push(LRes);
		raise ENotAggregated.Create('A list was found where a number was expected');
	end;

	result := LRes^.Number;
	Dispose(LRes);
end;

end.

