unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack

	body = statement
	statement = operation | block | operand

	operation = (prefix_op statement) | (statement infix_op statement)
	block = left_brace statement right_brace
	operand = number | variable

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

implementation

type
	TStatementFlag = (sfFull, sfNotOperation);
	TStatementFlags = set of TStatementFlag;
	TCharacterType = (ctWhiteSpace, ctLetter, ctDigit, ctDecimalSeparator, ctBrace, ctSymbol);

	TCleanupList = specialize TFPGObjectList<TPNNode>;

var
	GInput: String;
	GInputLength: UInt32;
	GAt: UInt32;
	GCleanup: TCleanupList;
	GCharacterTypes: Array of TCharacterType;

procedure InitGlobals(const ParseInput: String);
var
	I: Int32;
	LUnicodeStr: UnicodeString;
begin
	GInput := ParseInput;
	LUnicodeStr := UnicodeString(ParseInput);
	GInputLength := Length(GInput);
	GAt := 1;

	if Length(LUnicodeStr) <> GInputLength then
		raise EParsingFailed.Create('Non-ANSI input is not supported');

	SetLength(GCharacterTypes, GInputLength);
	for I := 0 to GInputLength - 1 do begin
		if IsWhiteSpace(LUnicodeStr[I + 1]) then
			GCharacterTypes[I] := ctWhiteSpace
		else if IsLetter(LUnicodeStr[I + 1]) or (LUnicodeStr[I + 1] = '_') then
			GCharacterTypes[I] := ctLetter
		else if IsDigit(LUnicodeStr[I + 1]) then
			GCharacterTypes[I] := ctDigit
		else if LUnicodeStr[I + 1] = cDecimalSeparator then
			GCharacterTypes[I] := ctDecimalSeparator
		else if (LUnicodeStr[I + 1] = '(') or (LUnicodeStr[I + 1] = ')') then
			GCharacterTypes[I] := ctBrace
		else
			GCharacterTypes[I] := ctSymbol
		;
	end;

	GCleanup := TCleanupList.Create;
end;

procedure DeInitGlobals();
begin
	GCleanup.Free;
end;

function ManagedNode(Item: TItem; FoundAt: Int32): TPNNode; Inline;
begin
	Item.ParsedAt := FoundAt;
	result := TPNNode.Create(Item);
	GCleanup.Add(result);
end;

function ParseStatement(Flags: TStatementFlags = []): TPNNode;
forward;

function IsWithinInput(): Boolean; Inline;
begin
	result := GAt <= GInputLength;
end;

function CharacterType(Position: UInt32): TCharacterType; Inline;
begin
	result := GCharacterTypes[Position - 1];
end;

procedure SkipWhiteSpace(); Inline;
begin
	while IsWithinInput() and (CharacterType(GAt) = ctWhiteSpace) do
		inc(GAt);
end;

function ParseWord(): Boolean;
begin
	if not (IsWithinInput() and (CharacterType(GAt) = ctLetter)) then
		exit(False);

	repeat
		inc(GAt);
	until not (IsWithinInput() and ((CharacterType(GAt) = ctLetter) or (CharacterType(GAt) = ctDigit)));

	result := True;
end;

function ParseSymbol(): Boolean;
begin
	if not (IsWithinInput() and (CharacterType(GAt) = ctSymbol)) then
		exit(False);

	repeat
		inc(GAt);
	until not (IsWithinInput() and (CharacterType(GAt) = ctSymbol));

	result := True;
end;

function ParseOp(OC: TOperationCategory): TPNNode;
var
	LSymbol: Boolean;
	LStart: UInt32;
	LOpInfo: TOperationInfo;
begin
	SkipWhiteSpace;
	result := nil;
	LStart := GAt;

	// word operator or symbolic operator
	LSymbol := not ParseWord;
	if LSymbol and not ParseSymbol() then exit;

	LOpInfo := TOperationInfo.Find(copy(GInput, LStart, GAt - LStart), OC);

	if (LOpInfo = nil) and LSymbol then begin
		// extra treatment for symbols (because of cases like *-)
		while GAt > LStart do begin
			Dec(GAt);
			LOpInfo := TOperationInfo.Find(copy(GInput, LStart, GAt - LStart), OC);
			if LOpInfo <> nil then break;
		end;
	end;

	if LOpInfo <> nil then
		result := ManagedNode(MakeItem(LOpInfo), LStart);
end;

function ParsePrefixOp(): TPNNode; Inline;
begin
	result := ParseOp(ocPrefix);
end;

function ParseInfixOp(): TPNNode; Inline;
begin
	result := ParseOp(ocInfix);
end;

function ParseOpeningBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (CharacterType(GAt) = ctBrace) and (GInput[GAt] = '(');
	if result then begin
		inc(GAt);
		SkipWhiteSpace();
	end;
end;

function ParseClosingBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (CharacterType(GAt) = ctBrace) and (GInput[GAt] = ')');
	if result then begin
		inc(GAt);
		SkipWhiteSpace();
	end;
end;

function ParseNumber(): TPNNode;
var
	LStart: UInt32;
	LNumber: TNumber;
begin
	SkipWhiteSpace();
	result := nil;

	LStart := GAt;
	LNumber := FastStrToFloat(GInput, GAt);

	if GAt > LStart then begin
		result := ManagedNode(MakeItem(LNumber), LStart);
		SkipWhiteSpace();
	end;
end;

function ParseVariableName(): TPNNode;
var
	LStart: UInt32;
	LVarName: TVariableName;
begin
	SkipWhiteSpace();

	LStart := GAt;
	if not ParseWord() then exit(nil);

	LVarName := copy(GInput, LStart, GAt - LStart);
	if TOperationInfo.Check(LVarName) then
		raise EInvalidVariableName.Create('Operator found where variable was expected: ' + LVarName);

	result := ManagedNode(MakeItem(LVarName), LStart);

	SkipWhiteSpace();
end;

function ParseBlock(): TPNNode;
var
	LAtBacktrack: UInt32;
begin
	LAtBacktrack := GAt;

	if ParseOpeningBrace() then begin
		result := ParseStatement();
		if result = nil then
			raise EInvalidStatement.Create('Invalid statement at offset ' + IntToStr(GAt));
		if not ParseClosingBrace() then
			raise EUnmatchedBraces.Create('Missing braces at offset ' + IntToStr(GAt));

		// mark result with higher precedendce as it is in block
		result.Grouped := True;
		exit(result);
	end;

	GAt := LAtBacktrack;
	result := nil;
end;

function ParseOperation(): TPNNode;
var
	LPartialResult, LOp, LFirst: TPNNode;
	LAtBacktrack: UInt32;

	function Success(): Boolean; Inline;
	begin
		result := LPartialResult <> nil;

		// backtrack
		if not result then
			GAt := LAtBacktrack;
	end;

	function IsLowerPriority(Compare, Against: TPNNode): Boolean; Inline;
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
	LAtBacktrack := GAt;

	LPartialResult := ParsePrefixOp();
	if Success then begin
		LOp := LPartialResult;
		LPartialResult := ParseStatement();
		if Success then begin
			LOp.Right := LPartialResult;

			// check grouping
			LPartialResult := LeftmostGrouped(LOp);
			if LPartialResult <> nil then begin
				result := LOp.Right;
				LPartialResult.Parent.Left := LOp;
				LOp.Right := LPartialResult;
				exit(result);
			end;

			// check precedence
			LPartialResult := LeftmostWithLowerPriority(LOp);
			if LPartialResult <> nil then begin
				result := LOp.Right;
				LOp.Right := LPartialResult.Left;
				LPartialResult.Left := LOp;
				exit(result);
			end;

			exit(LOp);
		end;
	end;

	LPartialResult := ParseStatement([sfNotOperation]);
	if Success then begin
		LFirst := LPartialResult;
		LPartialResult := ParseInfixOp();
		if Success then begin
			LOp := LPartialResult;
			LPartialResult := ParseStatement();
			if Success then begin
				// No need to check for precedence on left argument, as we
				// parse left to right (sfNotOperation on first)
				LOp.Left := LFirst;
				LOp.Right := LPartialResult;

				// check precedence
				LPartialResult := LeftmostWithLowerPriority(LOp);
				if LPartialResult <> nil then begin
					result := LOp.Right;
					LOp.Right := LPartialResult.Left;
					LPartialResult.Left := LOp;
				end
				else
					result := LOp;

				exit(result);
			end;
		end;
	end;

	result := nil;
end;

function ParseOperand(): TPNNode;
var
	LPartialResult: TPNNode;
	LAtBacktrack: UInt32;

	function Success(): Boolean; Inline;
	begin
		result := LPartialResult <> nil;

		// backtrack
		if not result then
			GAt := LAtBacktrack;
	end;

begin
	LAtBacktrack := GAt;

	LPartialResult := ParseNumber();
	if Success then exit(LPartialResult);

	LPartialResult := ParseVariableName();
	if Success then exit(LPartialResult);

	result := nil;
end;

function ParseStatement(Flags: TStatementFlags = []): TPNNode;
var
	LPartialResult: TPNNode;
	LAtBacktrack: UInt32;

	function Success(): Boolean; Inline;
	begin
		result := (LPartialResult <> nil) and ((not (sfFull in Flags)) or (GAt > GInputLength));

		// backtrack
		if not result then
			GAt := LAtBacktrack;
	end;

begin
	LAtBacktrack := GAt;

	if not (sfNotOperation in Flags) then begin
		LPartialResult := ParseOperation();
		if Success then exit(LPartialResult);
	end;

	LPartialResult := ParseBlock();
	if Success then exit(LPartialResult);

	// operand last, as it is a part of an operation
	LPartialResult := ParseOperand();
	if Success then exit(LPartialResult);

	result := nil;
end;

{ Parses the entire calculation }
function Parse(const ParseInput: String): TPNStack;
var
	LNode: TPNNode;
begin
	InitGlobals(ParseInput);

	try
		LNode := ParseStatement([sfFull]);
		if LNode = nil then
			raise EParsingFailed.Create('Couldn''t parse the calculation');

		result := TPNStack.Create;
		while LNode <> nil do begin
			result.Push(LNode.Item);
			LNode := LNode.NextPreorder();
		end;

	finally
		DeInitGlobals;
	end;
end;

{ Parses one variable name }
function ParseVariable(const ParseInput: String): String;
var
	LNode: TPNNode;
begin
	InitGlobals(ParseInput);

	try
		LNode := ParseVariableName;

		if not((LNode <> nil) and (GAt > GInputLength)) then
			raise EInvalidVariableName.Create('Invalid variable name ' + GInput);

		result := LNode.Item.VariableName;
	finally
		DeInitGlobals;
	end;
end;

end.

