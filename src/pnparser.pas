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

function Parse(const vInput: String): TPNStack;

implementation

type
	TStatementFlag = (sfFull, sfNotOperation);
	TStatementFlags = set of TStatementFlag;

var
	vInput: String;
	vInputLength: UInt32;
	vAt: UInt32;

function ParseStatement(vFlags: TStatementFlags = []): TPNNode;
forward;

function IsWithinInput(): Boolean;
begin
	result := vAt <= vInputLength;
end;

procedure SkipWhiteSpace();
begin
	while IsWithinInput() and IsWhiteSpace(vInput[vAt]) do
		inc(vAt);
end;

function ParseOp(vOC: TOperationCategory): TPNNode;
var
	vLen, vLongest: UInt32;
	vOp: TOperatorName;
	vOpInfo: TOperationInfo;
begin
	vLen := vInputLength - vAt + 1;
	vLongest := TOperationInfo.Longest(vOC);
	if vLen < vLongest then
		vLongest := vLen;

	result := nil;
	for vLen := vLongest downto 1 do begin
		vOp := copy(vInput, vAt, vLen);
		vOpInfo := TOperationInfo.Find(vOp, vOC);
		if vOpInfo <> nil then begin
			result := TPNNode.Create(MakeItem(vOpInfo));
			vAt := vAt + vLen;
			break;
		end;
	end;
end;

function ParsePrefixOp(): TPNNode;
begin
	// only skip whitespace at the front
	SkipWhiteSpace();

	result := ParseOp(ocPrefix);
end;

function ParseInfixOp(): TPNNode;
begin
	// no need to skip whitespace in infix ops, as they must be surrounded by
	// tokens which strip whitespace themselves
	result := ParseOp(ocInfix);
end;

function ParseOpeningBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (vInput[vAt] = '(');
	if result then begin
		inc(vAt);
		SkipWhiteSpace();
	end;
end;

function ParseClosingBrace(): Boolean;
begin
	SkipWhiteSpace();
	result := IsWithinInput() and (vInput[vAt] = ')');
	if result then begin
		inc(vAt);
		SkipWhiteSpace();
	end;
end;

function ParseNumber(): TPNNode;
var
	vStart: UInt32;
	vHadPoint: Boolean;
	vNumberStringified: String;
begin
	SkipWhiteSpace();

	vStart := vAt;
	if not (IsWithinInput() and IsDigit(vInput[vAt])) then
		exit(nil);

	vHadPoint := False;
	repeat
		if vInput[vAt] = '.' then begin
			if vHadPoint then exit(nil);
			vHadPoint := True;
		end;
		inc(vAt);
	until not (IsWithinInput() and (IsDigit(vInput[vAt]) or (vInput[vAt] = '.')));

	vNumberStringified := copy(vInput, vStart, vAt - vStart);
	result := TPNNode.Create(MakeItem(vNumberStringified));

	SkipWhiteSpace();
end;

function ParseVariableName(): TPNNode;
var
	vStart: UInt32;
	vVarName: TVariableName;
begin
	SkipWhiteSpace();

	vStart := vAt;
	if not (IsWithinInput() and (IsLetter(vInput[vAt]) or (vInput[vAt] = '_'))) then
		exit(nil);

	repeat
		inc(vAt);
	until not (IsWithinInput() and (IsLetterOrDigit(vInput[vAt]) or (vInput[vAt] = '_')));

	vVarName := copy(vInput, vStart, vAt - vStart);
	result := TPNNode.Create(MakeItem(vVarName));

	SkipWhiteSpace();
end;

function ParseBlock(): TPNNode;
var
	vAtBacktrack: UInt32;
begin
	vAtBacktrack := vAt;

	if ParseOpeningBrace() then begin
		result := ParseStatement();
		if (result <> nil) and ParseClosingBrace() then begin
			// mark result with higher precedendce as it is in block
			result.Grouped := True;
			exit(result);
		end;
	end;

	vAt := vAtBacktrack;
	result := nil;
end;

function ParseOperation(): TPNNode;
var
	vPartialResult, vOp, vFirst: TPNNode;
	vAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := vPartialResult <> nil;

		// backtrack
		if not result then
			vAt := vAtBacktrack;
	end;

	function IsLowerPriority(vCompare, vAgainst: TPNNode): Boolean;
	begin
		result := vCompare.IsOperation and (not vCompare.Grouped)
			and (vCompare.OperationPriority <= vAgainst.OperationPriority);
	end;

begin
	vOp := nil;
	vFirst := nil;
	vAtBacktrack := vAt;

	vPartialResult := ParsePrefixOp();
	if Success then begin
		vOp := vPartialResult;
		vPartialResult := ParseStatement();
		if Success then begin
			vOp.Left := vPartialResult;

			// check if vPartialResult is an operator (for precedence)
			// (must descent to find leftmost operator)
			if IsLowerPriority(vPartialResult, vOp) then begin
				while IsLowerPriority(vPartialResult.Left, vOp) do
					vPartialResult := vPartialResult.Left;
				result := vOp.Left;
				vOp.Left := vPartialResult.Left;
				result.Left := vOp;
			end
			else
				result := vOp;

			exit(result);
		end;
	end;

	vOp.Free;
	vPartialResult.Free;

	vPartialResult := ParseStatement([sfNotOperation]);
	if Success then begin
		vFirst := vPartialResult;
		vPartialResult := ParseInfixOp();
		if Success then begin
			vOp := vPartialResult;
			vPartialResult := ParseStatement();
			if Success then begin
				// No need to check for precedence on left argument, as we
				// parse left to right (sfNotOperation on first)
				vOp.Left := vFirst;
				vOp.Right := vPartialResult;

				// check if vPartialResult is an operator (for precedence)
				// (must descent to find leftmost operator)
				if IsLowerPriority(vPartialResult, vOp) then begin
					while IsLowerPriority(vPartialResult.Left, vOp) do
						vPartialResult := vPartialResult.Left;
					result := vOp.Right;
					vOp.Right := vPartialResult.Left;
					vPartialResult.Left := vOp;
				end
				else
					result := vOp;

				exit(result);
			end;
		end;
	end;

	vOp.Free;
	vPartialResult.Free;
	vFirst.Free;
	result := nil;
end;

function ParseOperand(): TPNNode;
var
	vPartialResult: TPNNode;
	vAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := vPartialResult <> nil;

		// backtrack
		if not result then
			vAt := vAtBacktrack;
	end;

begin
	vAtBacktrack := vAt;

	vPartialResult := ParseNumber();
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	vPartialResult := ParseVariableName();
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	result := nil;
end;

function ParseStatement(vFlags: TStatementFlags = []): TPNNode;
var
	vPartialResult: TPNNode;
	vAtBacktrack: UInt32;

	function Success(): Boolean;
	begin
		result := (vPartialResult <> nil) and ((not (sfFull in vFlags)) or (vAt > vInputLength));

		// backtrack
		if not result then
			vAt := vAtBacktrack;
	end;

begin
	vPartialResult := nil;
	vAtBacktrack := vAt;

	if not (sfNotOperation in vFlags) then begin
		vPartialResult := ParseOperation();
		if Success then exit(vPartialResult);
	end;

	vPartialResult.Free;
	vPartialResult := ParseBlock();
	if Success then exit(vPartialResult);

	// operand last, as it is a part of an operation
	vPartialResult.Free;
	vPartialResult := ParseOperand();
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	result := nil;
end;

function ParseBody(const vParseInput: String): TPNNode;
begin
	vInput := vParseInput;
	vInputLength := length(vInput);
	vAt := 1;
	result := ParseStatement([sfFull]);

	if result = nil then
		raise Exception.Create('Couldn''t parse the calculation');
end;

{ Parses the entire calculation }
function Parse(const vInput: String): TPNStack;
var
	vNode: TPNNode;
begin
	vNode := ParseBody(vInput);

	result := TPNStack.Create;
	while vNode <> nil do begin
		result.Push(vNode.Item);
		vNode := vNode.NextPreorder();
	end;
end;

end.

