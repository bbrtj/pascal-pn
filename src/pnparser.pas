unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack

	body = statement
	statement = block | operand | operation

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

function ParseStatement(const vInput: String; var vAt: UInt32; vFlags: TStatementFlags = []): TPNNode;
forward;

function IsWithinInput(const vInput: String; var vAt: UInt32): Boolean;
begin
	result := vAt <= length(vInput);
end;

procedure SkipWhiteSpace(const vInput: String; var vAt: UInt32);
begin
	while IsWithinInput(vInput, vAt) and IsWhiteSpace(vInput[vAt]) do
		inc(vAt);
end;

function ParseOp(const vInput: String; var vAt: UInt32; vOC: TOperationCategory): TPNNode;
var
	vLen, vLongest: UInt32;
	vOp: TOperatorName;
	vOpInfo: TOperationInfo;
begin
	vLen := length(vInput) - vAt + 1;
	vLongest := TOperationInfo.Longest(vOC);
	if vLen < vLongest then
		vLongest := vLen;

	result := nil;
	for vLen := vLongest downto 1 do begin
		vOp := copy(vInput, vAt, vLen);
		vOpInfo := TOperationInfo.Find(vOp, vOC);
		if vOpInfo <> nil then begin
			result := TPNNode.Create(MakeItem(vOpInfo));
			break;
		end;
	end;
end;

function ParsePrefixOp(const vInput: String; var vAt: UInt32): TPNNode;
begin
	// only skip whitespace at the front
	SkipWhiteSpace(vInput, vAt);

	result := ParseOp(vInput, vAt, ocPrefix);
end;

function ParseInfixOp(const vInput: String; var vAt: UInt32): TPNNode;
begin
	// no need to skip whitespace in infix ops, as they must be surrounded by
	// tokens which strip whitespace themselves
	result := ParseOp(vInput, vAt, ocInfix);
end;

function ParseOpeningBrace(const vInput: String; var vAt: UInt32): Boolean;
begin
	SkipWhiteSpace(vInput, vAt);
	result := IsWithinInput(vInput, vAt) and (vInput[vAt] = '(');
	if result then begin
		inc(vAt);
		SkipWhiteSpace(vInput, vAt);
	end;
end;

function ParseClosingBrace(const vInput: String; var vAt: UInt32): Boolean;
begin
	SkipWhiteSpace(vInput, vAt);
	result := IsWithinInput(vInput, vAt) and (vInput[vAt] = ')');
	if result then begin
		inc(vAt);
		SkipWhiteSpace(vInput, vAt);
	end;
end;

function ParseNumber(const vInput: String; var vAt: UInt32): TPNNode;
var
	vStart: UInt32;
	vHadPoint: Boolean;
	vNumberStringified: String;
begin
	SkipWhiteSpace(vInput, vAt);

	vStart := vAt;
	if not (IsWithinInput(vInput, vAt) and IsDigit(vInput[vAt])) then
		exit(nil);

	vHadPoint := False;
	repeat
		if vInput[vAt] = '.' then begin
			if vHadPoint then exit(nil);
			vHadPoint := True;
		end;
		inc(vAt);
	until not (IsWithinInput(vInput, vAt) and (IsDigit(vInput[vAt]) or (vInput[vAt] = '.')));

	vNumberStringified := copy(vInput, vStart, vAt - 1);
	result := TPNNode.Create(MakeItem(vNumberStringified));

	SkipWhiteSpace(vInput, vAt);
end;

function ParseVariableName(const vInput: String; var vAt: UInt32): TPNNode;
var
	vStart: UInt32;
	vVarName: TVariableName;
begin
	SkipWhiteSpace(vInput, vAt);

	vStart := vAt;
	if not (IsWithinInput(vInput, vAt) and (IsLetter(vInput[vAt]) or (vInput[vAt] = '_'))) then
		exit(nil);

	repeat
		inc(vAt);
	until not (IsWithinInput(vInput, vAt) and (IsLetterOrDigit(vInput[vAt]) or (vInput[vAt] = '_')));

	vVarName := copy(vInput, vStart, vAt - 1);
	result := TPNNode.Create(MakeItem(vVarName));

	SkipWhiteSpace(vInput, vAt);
end;

function ParseBlock(const vInput: String; var vAt: UInt32): TPNNode;
var
	vAtBacktrack: UInt32;

begin
	vAtBacktrack := vAt;

	if ParseOpeningBrace(vInput, vAt) then begin
		result := ParseStatement(vInput, vAt);
		if (result <> nil) and ParseClosingBrace(vInput, vAt) then begin
			// mark result with higher precedendce as it is in block
			result.Grouped := True;
			exit(result);
		end;
	end;

	vAt := vAtBacktrack;
	result := nil;
end;

function ParseOperation(const vInput: String; var vAt: UInt32): TPNNode;
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
			and (vCompare.OperationPriority < vAgainst.OperationPriority);
	end;

begin
	vOp := nil;
	vFirst := nil;
	vAtBacktrack := vAt;

	vPartialResult := ParsePrefixOp(vInput, vAt);
	if Success then begin
		vOp := vPartialResult;
		vPartialResult := ParseStatement(vInput, vAt);
		if Success then begin
			// check if vPartialResult is an operator (for precedence)
			if IsLowerPriority(vPartialResult, vOp) then begin
				vOp.Left := vPartialResult.Left;
				result := vPartialResult;
				vPartialResult := vOp;
			end
			else
				result := vOp;

			result.Left := vPartialResult;
			exit(result);
		end;
	end;

	vOp.Free;
	vPartialResult.Free;

	vPartialResult := ParseStatement(vInput, vAt, [sfNotOperation]);
	if Success then begin
		vFirst := vPartialResult;
		vPartialResult := ParseInfixOp(vInput, vAt);
		if Success then begin
			vOp := vPartialResult;
			vPartialResult := ParseStatement(vInput, vAt);
			if Success then begin
				result := vOp;

				// No need to check for precedence on left argument, as we
				// parse left to right
				result.Left := vFirst;
				result.Right := vPartialResult;

				// check if vPartialResult is an operator (for precedence)
				if IsLowerPriority(vPartialResult, result) then begin
					result.Right := vPartialResult.Left;
					vPartialResult.Left := result;
				end;

				exit(result);
			end;
		end;
	end;

	vOp.Free;
	vPartialResult.Free;
	vFirst.Free;
	result := nil;
end;

function ParseOperand(const vInput: String; var vAt: UInt32): TPNNode;
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

	vPartialResult := ParseNumber(vInput, vAt);
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	vPartialResult := ParseVariableName(vInput, vAt);
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	result := nil;
end;

function ParseStatement(const vInput: String; var vAt: UInt32; vFlags: TStatementFlags = []): TPNNode;
var
	vPartialResult: TPNNode;
	vAtBacktrack: UInt32;
	vLength: UInt32;

	function Success(): Boolean;
	begin
		result := (vPartialResult <> nil) and ((not (sfFull in vFlags)) or (vAt > vLength));

		// backtrack
		if not result then
			vAt := vAtBacktrack;
	end;

begin
	vAtBacktrack := vAt;
	vLength := Length(vInput);

	vPartialResult := ParseBlock(vInput, vAt);
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	vPartialResult := ParseOperand(vInput, vAt);
	if Success then exit(vPartialResult);

	if not (sfNotOperation in vFlags) then begin
		vPartialResult.Free;
		vPartialResult := ParseOperation(vInput, vAt);
		if Success then exit(vPartialResult);
	end;

	vPartialResult.Free;
	result := nil;
end;

function ParseBody(const vInput: String): TPNNode;
var
	vAt: UInt32;
begin
	vAt := 1;
	result := ParseStatement(vInput, vAt, [sfFull]);

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

