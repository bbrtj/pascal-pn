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
	Fgl, SysUtils, Character, Math,
	PNTree, PNStack, PNBase;

function Parse(const ParseInput: String): TPNStack;
function ParseVariable(const ParseInput: String): String;

implementation

type
	TStatementFlag = (sfFull, sfNotOperation);
	TStatementFlags = set of TStatementFlag;

	TCleanupList = specialize TFPGObjectList<TPNNode>;

var
	GInput: UnicodeString;
	GInputLength: UInt32;
	GAt: UInt32;
	GLongestOperator: Array [TOperationCategory] of UInt32;
	GCleanup: TCleanupList;

function ManagedNode(const Item: TItem): TPNNode; Inline;
begin
	result := TPNNode.Create(Item);
	GCleanup.Add(result);
end;

function ParseStatement(Flags: TStatementFlags = []): TPNNode;
forward;

function IsWithinInput(): Boolean; Inline;
begin
	result := GAt <= GInputLength;
end;

procedure SkipWhiteSpace(); Inline;
begin
	while IsWithinInput() and IsWhiteSpace(GInput[GAt]) do
		inc(GAt);
end;

function ParseWord(): Boolean;
begin
	if not (IsWithinInput() and (IsLetter(GInput[GAt]) or (GInput[GAt] = '_'))) then
		exit(False);

	repeat
		inc(GAt);
	until not (IsWithinInput() and (IsLetterOrDigit(GInput[GAt]) or (GInput[GAt] = '_')));

	result := True;
end;

function ParseOp(OC: TOperationCategory): TPNNode;
var
	LLen: UInt32;
	LOp: TOperatorName;
	LOpInfo: TOperationInfo;
begin
	SkipWhiteSpace;

	// word operator
	LLen := GAt;
	if ParseWord() then begin
		result := nil;

		LOp := copy(GInput, LLen, GAt - LLen);
		LOpInfo := TOperationInfo.Find(LOp, OC);
		if LOpInfo <> nil then
			result := ManagedNode(MakeItem(LOpInfo));

		exit(result);
	end;

	// symbolic operator
	LLen := GInputLength - GAt + 1;
	result := nil;
	for LLen := Min(LLen, GLongestOperator[OC]) downto 1 do begin
		LOp := copy(GInput, GAt, LLen);
		LOpInfo := TOperationInfo.Find(LOp, OC);
		if LOpInfo <> nil then begin
			result := ManagedNode(MakeItem(LOpInfo));
			GAt := GAt + LLen;
			break;
		end;
	end;
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
	result := IsWithinInput() and (GInput[GAt] = '(');
	if result then begin
		inc(GAt);
		SkipWhiteSpace();
	end;
end;

function ParseClosingBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (GInput[GAt] = ')');
	if result then begin
		inc(GAt);
		SkipWhiteSpace();
	end;
end;

function ParseNumber(): TPNNode;
var
	LStart: UInt32;
	LHadPoint: Boolean;
	LNumberStringified: String;
begin
	SkipWhiteSpace();

	LStart := GAt;
	if not (IsWithinInput() and IsDigit(GInput[GAt])) then
		exit(nil);

	LHadPoint := False;
	repeat
		if GInput[GAt] = cDecimalSeparator then begin
			if LHadPoint then exit(nil);
			LHadPoint := True;
		end;
		inc(GAt);
	until not (IsWithinInput() and (IsDigit(GInput[GAt]) or (GInput[GAt] = cDecimalSeparator)));

	LNumberStringified := copy(GInput, LStart, GAt - LStart);
	result := ManagedNode(MakeItem(LNumberStringified));

	SkipWhiteSpace();
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
		exit(nil);

	result := ManagedNode(MakeItem(LVarName));

	SkipWhiteSpace();
end;

function ParseBlock(): TPNNode;
var
	GAtBacktrack: UInt32;
begin
	GAtBacktrack := GAt;

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

	GAt := GAtBacktrack;
	result := nil;
end;

function ParseOperation(): TPNNode;
var
	LPartialResult, LOp, LFirst: TPNNode;
	GAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := LPartialResult <> nil;

		// backtrack
		if not result then
			GAt := GAtBacktrack;
	end;

	function IsLowerPriority(Compare, Against: TPNNode): Boolean; Inline;
	begin
		result := (Compare <> nil) and Compare.IsOperation and (not Compare.Grouped)
			and (Compare.OperationPriority <= Against.OperationPriority);
	end;

	function IsLeftGrouped(Compare: TPNNode): Boolean; Inline;
	begin
		result := (Compare <> nil) and Compare.IsOperation and (not Compare.Grouped)
			and (Compare.Left <> nil) and Compare.Left.Grouped;
	end;

begin
	GAtBacktrack := GAt;

	LPartialResult := ParsePrefixOp();
	if Success then begin
		LOp := LPartialResult;
		LPartialResult := ParseStatement();
		if Success then begin
			LOp.Right := LPartialResult;

			// check if LPartialResult is an operator (for precedence)
			// (must descent to find leftmost operator which has a left part)
			// (also do it if the left item is grouped while the entire statement is not)
			if IsLeftGrouped(LPartialResult) or
				(IsLowerPriority(LPartialResult, LOp) and (LPartialResult.Left <> nil)) then begin
				while IsLowerPriority(LPartialResult.Left, LOp)
					and (LPartialResult.Left.Left <> nil) do
					LPartialResult := LPartialResult.Left;
				result := LOp.Right;
				LOp.Right := LPartialResult.Left;
				LPartialResult.Left := LOp;
			end
			else
				result := LOp;

			exit(result);
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

				// check if LPartialResult is an operator (for precedence)
				// (must descent to find leftmost operator)
				if IsLowerPriority(LPartialResult, LOp) and (LPartialResult.Left <> nil) then begin
					while IsLowerPriority(LPartialResult.Left, LOp) do
						LPartialResult := LPartialResult.Left;
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
	GAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := LPartialResult <> nil;

		// backtrack
		if not result then
			GAt := GAtBacktrack;
	end;

begin
	GAtBacktrack := GAt;

	LPartialResult := ParseNumber();
	if Success then exit(LPartialResult);

	LPartialResult := ParseVariableName();
	if Success then exit(LPartialResult);

	result := nil;
end;

function ParseStatement(Flags: TStatementFlags = []): TPNNode;
var
	LPartialResult: TPNNode;
	GAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := (LPartialResult <> nil) and ((not (sfFull in Flags)) or (GAt > GInputLength));

		// backtrack
		if not result then
			GAt := GAtBacktrack;
	end;

begin
	GAtBacktrack := GAt;

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
	GCleanup := TCleanupList.Create;
	GInput := UnicodeString(ParseInput);
	GInputLength := length(GInput);
	GAt := 1;

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
		GCleanup.Free;
	end;
end;

{ Parses one variable name }
function ParseVariable(const ParseInput: String): String;
var
	LNode: TPNNode;
begin
	GCleanup := TCleanupList.Create;
	GInput := UnicodeString(ParseInput);
	GInputLength := length(GInput);
	GAt := 1;

	try
		LNode := ParseVariableName;

		if not((LNode <> nil) and (GAt > GInputLength)) then
			raise EInvalidVariableName.Create('Invalid variable name ' + GInput);

		result := LNode.Item.VariableName;
	finally
		GCleanup.Free;
	end;
end;

var
	LOC: TOperationCategory;
initialization
	for LOC in TOperationCategory do
		GLongestOperator[LOC] := TOperationInfo.LongestSymbolic(LOC);
end.

