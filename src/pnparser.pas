unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack

	body = statement
	statement = block | operation | operand

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
	PNTree, PNStack, PNTypes;

function Parse(const vInput: String): TPNStack;

implementation

function IsWithinInput(const vInput: String; var vAt: UInt32): Boolean;
begin
	result := vAt <= length(vInput);
end;

procedure SkipWhiteSpace(const vInput: String; var vAt: UInt32);
begin
	while IsWithinInput(vInput, vAt) and IsWhiteSpace(vInput[vAt]) do
		inc(vAt);
end;

function ParsePrefixOp(const vInput: String; var vAt: UInt32): TPNNode;
begin
	// only skip whitespace at the front
	SkipWhiteSpace;
end;

function ParseInfixOp(const vInput: String; var vAt: UInt32): TPNNode;
begin
	// no need to skip whitespace in infix ops, as they must be surrounded by
	// tokens which strip whitespace themselves
end;

function ParseOpeningBrace(const vInput: String; var vAt: UInt32): Boolean;
begin
	SkipWhiteSpace;
	result := IsWithinInput(vInput, vAt) and (vInput[vAt] = '(');
	if result then begin
		inc(vAt);
		SkipWhiteSpace;
	end;
end;

function ParseClosingBrace(const vInput: String; var vAt: UInt32): Boolean;
begin
	SkipWhiteSpace;
	result := IsWithinInput(vInput, vAt) and (vInput[vAt] = ')');
	if result then begin
		inc(vAt);
		SkipWhiteSpace;
	end;
end;

function ParseNumber(const vInput: String; var vAt: UInt32): TPNNode;
var
	vStart: UInt32;
	vHadPoint: Boolean;
	vNumberStringified: String;
begin
	SkipWhiteSpace;

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
	until not (IsWithinInput(vInput, vAt) and (IsDigit(vInput[vAt]) or (vInput[vAt] = '.'));

	vNumberStringified := copy(vInput, vStart, vAt - 1);
	result := TPNNode.Create(MakeItem(vNumberStringified));

	SkipWhiteSpace;
end;

function ParseVariableName(const vInput: String; var vAt: UInt32): TPNNode;
var
	vStart: UInt32;
	vVarName: TVariableName;
begin
	SkipWhiteSpace;

	vStart := vAt;
	if not (IsWithinInput(vInput, vAt) and (IsLetter(vInput[vAt]) or (vInput[vAt] = '_'))) then
		exit(nil);

	repeat
		inc(vAt);
	until not (IsWithinInput(vInput, vAt) and (IsLetterOrDigit(vInput[vAt]) or (vInput[vAt] = '_'));

	vVarName := copy(vInput, vStart, vAt - 1);
	result := TPNNode.Create(MakeItem(vVarName));

	SkipWhiteSpace;
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
			result.OperationInfo.Priority += cMaxPriority;
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

begin
	vAtBacktrack := vAt;

	vPartialResult := ParsePrefixOp(vInput, vAt);
	if Success then begin
		vOp := vPartialResult;
		vPartialResult := ParseStatement(vInput, vAt);
		if Success then begin
			// check if vPartialResult is an operator (for precedence)
			// TODO check braces
			if vPartialResult.IsOperation
				and (vPartialResult.OperationPriority < vOp.OperationPriority) then begin
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

	vPartialResult := ParseStatement(vInput, vAt);
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
				// TODO check braces
				if vPartialResult.IsOperation
					and (vPartialResult.OperationPriority < result.OperationPriority) then begin
					result.Right := vPartialResult.Left;
					vPartialResult.Left := result;
				end

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

function ParseStatement(const vInput: String; var vAt: UInt32, vFull: Boolean = False): TPNNode;
var
	vPartialResult: TPNNode;
	vAtBacktrack: UInt32;
	vLength: UInt32;

	function Success(): Boolean;
	begin
		result := (vPartialResult <> nil) and ((not vFull) or (vAt > vLength));

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
	vPartialResult := ParseOperation(vInput, vAt);
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	vPartialResult := ParseOperand(vInput, vAt);
	if Success then exit(vPartialResult);

	vPartialResult.Free;
	result := nil;
end;

function ParseBody(const vInput: String): TPNNode;
var
	vAt: UInt32;
begin
	vAt := 1;
	result := ParseStatement(vInput, vAt, True);

	if result <> nil then begin
	end;
end;

function Tokenize(const vInput: String): TPNNode;

	procedure AddNode(vNode, vLastOperation: TPNNode; vRoot: PPNNode);
	begin
		if vLastOperation <> nil then begin
			if (vLastOperation.OperationType() = otInfix) and (vLastOperation.Right = nil) then
				vLastOperation.Right := vNode
			else
				raise Exception.Create(
					Format('Unexpected value %S (operator %S)', [
						GetItemValue(vNode.Item),
						vLastOperation.Item.OperatorName
					])
				);
		end
		else if vRoot^ = nil then
			vRoot^ := vNode
		else
			raise Exception.Create(Format('Unexpected value %S', [GetItemValue(vNode.Item)]));
	end;

	{ Recursively transform standard notation into a tree }
	function MakeTree(var vIndex: Word; vInBraces: Boolean = False): TPNNode;
	var
		vLastOperation: TPNNode;
		vCurrentRoot: TPNNode;
		vNode: TPNNode;
		vTmp: TPNNode;
	begin
		vLastOperation := nil;
		vCurrentRoot := nil;

		while vIndex < vTokens.Count do begin
			vNode := vTokens[vIndex];

			if vNode.Item.ItemType = itOperator then begin
				vNode.OperationInfo := GetOperationInfoByOperator(vNode.Item.OperatorName);

				if vNode.OperationType() = otSyntax then begin
					case vNode.OperationInfo.Syntax of
						stGroupStart: begin
							vIndex += 1;
							vNode := MakeTree(vIndex, True);
							AddNode(vNode, vLastOperation, @vCurrentRoot);
						end;

						stGroupEnd: begin
							vInBraces := not vInBraces;
							break;
						end;
					end;
				end

				else begin
					while (vLastOperation <> nil) and (vLastOperation.OperationPriority() >= vNode.OperationPriority()) do
						vLastOperation := vLastOperation.Parent;

					if vLastOperation = nil then begin
						vNode.Left := vCurrentRoot;
						vCurrentRoot := vNode;
					end

					else begin
						vTmp := vLastOperation.Right;
						vLastOperation.Right := vNode;
						vNode.Left := vTmp;
					end;

					vLastOperation := vNode;
				end;
			end

			else
				AddNode(vNode, vLastOperation, @vCurrentRoot);

			vIndex += 1;
		end;

		if vInBraces then
			raise Exception.Create('Unmatched braces');

		result := vCurrentRoot;
	end;

var
	vIndex: Word;
begin
	vIndex := 0;
	result := MakeTree(vIndex);
end;

{ Parses the entire calculation }
function Parse(const vInput: String): TPNStack;
var
	vNode: TPNNode;
begin
	vNode := TransformTokenList(vInput);

	result := TPNStack.Create;
	while vNode <> nil do begin
		result.Push(vNode.Item);
		vNode := vNode.NextInorder();
	end;

	vTokens.Free();
end;

end.

