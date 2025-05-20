unit PNParser;

{$mode objfpc}{$H+}{$J-}

{$ifdef RELEASE}{$optimization autoinline}{$endif}

{
	Code responsible for transforming a string into a PN stack

	body = statement
	statement = (prefix_op statement) | (operand [infix_op statement])
	operand = block | number | variable
	block = left_brace statement right_brace

	infix_op = <any of infix operators>
	prefix_op = <any of prefix operators>
	number = <any number>
	variable = <alphanumeric variable>
	left_brace = '('
	right_brace = ')'
}

interface

uses
	Fgl, SysUtils, Character,
	PNTree, PNStack, PNBase;

function Parse(const ParseInput: String): TPNStack;
function ParseVariable(const ParseInput: String): String;

implementation // more internal interface below

type
	TCharacterType = (ctWhiteSpace, ctLetter, ctDigit, ctBrace, ctSymbol);
	TCleanupList = specialize TFPGObjectList<TPNNode>;

	TParseContext = class
	strict private
		FInput: String;
		FInputLength: UInt32;
		FAt: UInt32;
		FCleanup: TCleanupList;
		FCharacterTypes: Array of TCharacterType;

		function ManagedNode(Item: TItem; FoundAt: Int32): TPNNode;
		function SuccessBacktrack(Parsed: TPNNode; Backtrack: UInt32): Boolean;
		procedure SuccessException(Parsed: TPNNode; AClass: TParsingFailedClass; const ExMsg: String);
		function IsWithinInput(): Boolean;
		function CharacterType(Position: UInt32): TCharacterType;
		procedure SkipWhiteSpace();

	public
		constructor Create(const ParseInput: String);
		destructor Destroy; override;

		procedure ReportException(AClass: TParsingFailedClass; const ExMsg: String);
		function Finished(): Boolean;

		function ParseWord(): Boolean;
		function ParseSymbol(): Boolean;
		function ParseOp(OC: TOperationCategory): TPNNode;
		function ParseOpeningBrace(): Boolean;
		function ParseClosingBrace(): Boolean;
		function ParseBlock(): TPNNode;
		function ParseNumber(): TPNNode;
		function ParseVariableName(): TPNNode;
		function ParseOperand(): TPNNode;
		function ParseStatement(): TPNNode;
	end;

{ implementation }

constructor TParseContext.Create(const ParseInput: String);
var
	I: Int32;
	LUnicodeStr: UnicodeString;
begin
	FInput := ParseInput;
	LUnicodeStr := UnicodeString(ParseInput);
	FInputLength := Length(FInput);
	FAt := 1;

	if Length(LUnicodeStr) <> FInputLength then
		ReportException(EParsingFailed, 'Non-ANSI input is not supported');

	SetLength(FCharacterTypes, FInputLength);
	for I := 0 to FInputLength - 1 do begin
		if IsWhiteSpace(LUnicodeStr[I + 1]) then
			FCharacterTypes[I] := ctWhiteSpace
		else if IsLetter(LUnicodeStr[I + 1]) or (LUnicodeStr[I + 1] = '_') then
			FCharacterTypes[I] := ctLetter
		else if IsDigit(LUnicodeStr[I + 1]) then
			FCharacterTypes[I] := ctDigit
		else if (LUnicodeStr[I + 1] = '(') or (LUnicodeStr[I + 1] = ')') then
			FCharacterTypes[I] := ctBrace
		else
			FCharacterTypes[I] := ctSymbol
		;
	end;

	FCleanup := TCleanupList.Create;
end;

destructor TParseContext.Destroy();
begin
	FCleanup.Free;
end;

procedure TParseContext.ReportException(AClass: TParsingFailedClass; const ExMsg: String);
begin
	raise AClass.Create(ExMsg + ' (at offset ' + IntToStr(FAt - 1) + ')');
end;

function TParseContext.Finished(): Boolean;
begin
	SkipWhiteSpace();
	result := not IsWithinInput();
end;

function TParseContext.ManagedNode(Item: TItem; FoundAt: Int32): TPNNode;
begin
	Item.ParsedAt := FoundAt;
	result := TPNNode.Create(Item);
	FCleanup.Add(result);
end;

function TParseContext.SuccessBacktrack(Parsed: TPNNode; Backtrack: UInt32): Boolean;
begin
	result := Parsed <> nil;

	if not result then
		FAt := Backtrack;
end;

procedure TParseContext.SuccessException(Parsed: TPNNode; AClass: TParsingFailedClass; const ExMsg: String);
begin
	if Parsed = nil then
		ReportException(AClass, ExMsg);
end;

function TParseContext.IsWithinInput(): Boolean;
begin
	result := FAt <= FInputLength;
end;

function TParseContext.CharacterType(Position: UInt32): TCharacterType;
begin
	result := FCharacterTypes[Position - 1];
end;

procedure TParseContext.SkipWhiteSpace();
begin
	while IsWithinInput() and (CharacterType(FAt) = ctWhiteSpace) do
		inc(FAt);
end;

function TParseContext.ParseWord(): Boolean;
begin
	if not (IsWithinInput() and (CharacterType(FAt) = ctLetter)) then
		exit(False);

	repeat
		inc(FAt);
	until not (IsWithinInput() and ((CharacterType(FAt) = ctLetter) or (CharacterType(FAt) = ctDigit)));

	result := True;
end;

function TParseContext.ParseSymbol(): Boolean;
begin
	if not (IsWithinInput() and (CharacterType(FAt) = ctSymbol)) then
		exit(False);

	repeat
		inc(FAt);
	until not (IsWithinInput() and (CharacterType(FAt) = ctSymbol));

	result := True;
end;

function TParseContext.ParseOp(OC: TOperationCategory): TPNNode;
var
	LSymbol: Boolean;
	LStart: UInt32;
	LOpInfo: TOperationInfo;
begin
	SkipWhiteSpace;
	result := nil;
	LStart := FAt;

	// word operator or symbolic operator
	LSymbol := not ParseWord;
	if LSymbol and not ParseSymbol() then exit;

	LOpInfo := TOperationInfo.Find(copy(FInput, LStart, FAt - LStart), OC);

	if (LOpInfo = nil) and LSymbol then begin
		// extra treatment for symbols (because of cases like *-)
		while FAt > LStart do begin
			Dec(FAt);
			LOpInfo := TOperationInfo.Find(copy(FInput, LStart, FAt - LStart), OC);
			if LOpInfo <> nil then break;
		end;
	end;

	if LOpInfo <> nil then
		result := ManagedNode(MakeItem(LOpInfo), LStart);
end;

function TParseContext.ParseOpeningBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (CharacterType(FAt) = ctBrace) and (FInput[FAt] = '(');
	if result then
		inc(FAt);
end;

function TParseContext.ParseClosingBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (CharacterType(FAt) = ctBrace) and (FInput[FAt] = ')');
	if result then
		inc(FAt);
end;

function TParseContext.ParseNumber(): TPNNode;
var
	LStart: UInt32;
	LNumber: TNumber;
begin
	SkipWhiteSpace();
	result := nil;

	LStart := FAt;
	LNumber := FastStrToFloat(FInput, FAt);

	if FAt > LStart then
		result := ManagedNode(MakeItem(LNumber), LStart);
end;

function TParseContext.ParseVariableName(): TPNNode;
var
	LStart: UInt32;
	LVarName: TVariableName;
begin
	SkipWhiteSpace();

	LStart := FAt;
	if not ParseWord() then exit(nil);

	LVarName := copy(FInput, LStart, FAt - LStart);
	if TOperationInfo.Check(LVarName) then begin
		FAt := LStart;
		exit(nil);
	end;

	result := ManagedNode(MakeItem(LVarName), LStart);
end;

function TParseContext.ParseBlock(): TPNNode;
begin
	result := nil;

	if ParseOpeningBrace() then begin
		result := ParseStatement();
		if result = nil then
			ReportException(EInvalidStatement, 'Invalid statement');

		if not ParseClosingBrace() then
			ReportException(EUnmatchedBraces, 'Missing braces');

		// mark result with higher precedendce as it is in block
		result.Grouped := True;
	end;
end;

function TParseContext.ParseOperand(): TPNNode;
begin
	result := ParseBlock();
	if result = nil then result := ParseNumber();
	if result = nil then result := ParseVariableName();
end;

function TParseContext.ParseStatement(): TPNNode;
var
	LPartialResult, LOp, LFirst: TPNNode;
	LAtBacktrack: UInt32;

	function IsLowerPriority(Compare, Against: TPNNode): Boolean;
	begin
		result := (Compare <> nil) and (Compare.Left <> nil)
			and Compare.IsOperation and (not Compare.Grouped)
			and (Compare.OperationPriority <= Against.OperationPriority);
	end;

	function LeftmostWithLowerPriority(Node: TPNNode): TPNNode;
	begin
		result := Node.Right;
		if not IsLowerPriority(result, Node) then exit(nil);

		while IsLowerPriority(result.Left, Node) do
			result := result.Left;
	end;

	function LeftmostGrouped(Node: TPNNode): TPNNode;
	begin
		result := Node.Right;

		while (result <> nil) and not result.Grouped do
			result := result.Left;

		if result = Node.Right then exit(nil);
		if (result <> nil) and not result.Grouped then exit(nil);
	end;

begin
	LAtBacktrack := FAt;

	LPartialResult := ParseOp(ocPrefix);
	if SuccessBacktrack(LPartialResult, LAtBacktrack) then begin
		LOp := LPartialResult;

		LPartialResult := ParseStatement();
		SuccessException(LPartialResult, EInvalidStatement, 'Invalid statement');

		LOp.Right := LPartialResult;
		result := LOp;

		// check grouping
		LPartialResult := LeftmostGrouped(LOp);
		if LPartialResult <> nil then begin
			result := LOp.Right;
			LPartialResult.Parent.Left := LOp;
			LOp.Right := LPartialResult;
		end;

		// check precedence
		LPartialResult := LeftmostWithLowerPriority(LOp);
		if LPartialResult <> nil then begin
			result := LOp.Right;
			LOp.Right := LPartialResult.Left;
			LPartialResult.Left := LOp;
		end;

		exit(result);
	end;

	LPartialResult := ParseOperand();
	if SuccessBacktrack(LPartialResult, LAtBacktrack) then begin
		LFirst := LPartialResult;

		// We successfully parsed the operand, so there's no need to backtrack
		// before it anymore
		LAtBacktrack := FAt;
		LPartialResult := ParseOp(ocInfix);

		// if we failed to parse an operator, backtrack before what we parsed
		// and exit with the operand. Stuff on the right are optional after the
		// operand
		if not SuccessBacktrack(LPartialResult, LAtBacktrack) then exit(LFirst);

		LOp := LPartialResult;
		LPartialResult := ParseStatement();
		SuccessException(LPartialResult, EInvalidStatement, 'Invalid statement');

		// No need to check for precedence on left argument, as we
		// parse left to right
		LOp.Left := LFirst;
		LOp.Right := LPartialResult;
		result := LOp;

		// check precedence
		LPartialResult := LeftmostWithLowerPriority(LOp);
		if LPartialResult <> nil then begin
			result := LOp.Right;
			LOp.Right := LPartialResult.Left;
			LPartialResult.Left := LOp;
		end;

		exit(result);
	end;

	result := nil;
end;

{ Parses the entire calculation }
function Parse(const ParseInput: String): TPNStack;
var
	LNode: TPNNode;
	LContext: TParseContext;
begin
	LContext := TParseContext.Create(ParseInput);

	try
		LNode := LContext.ParseStatement();

		if (LNode = nil) or not LContext.Finished() then
			LContext.ReportException(EParsingFailed, 'Couldn''t parse the calculation');

		result := TPNStack.Create;
		while LNode <> nil do begin
			result.Push(LNode.Item);
			LNode := LNode.NextPreorder();
		end;
	finally
		LContext.Free;
	end;
end;

{ Parses one variable name }
function ParseVariable(const ParseInput: String): String;
var
	LNode: TPNNode;
	LContext: TParseContext;
begin
	LContext := TParseContext.Create(ParseInput);

	try
		LNode := LContext.ParseVariableName;

		if (LNode = nil) or not LContext.Finished() then
			LContext.ReportException(EInvalidVariableName, 'Invalid variable name ' + ParseInput);

		result := LNode.Item.VariableName;
	finally
		LContext.Free;
	end;
end;

end.

