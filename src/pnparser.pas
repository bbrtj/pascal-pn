unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack

	body = statement
	statement = operation | operand | block

	operation = (prefix_op statement) | (statement infix_op statement)
	block = '(' statement ')'
	operand = number | variable

	infix_op = <any of infix operators>
	prefix_op = <any of prefix operators>
	number = <any number>
	variable = <alphanumeric variable>
}

interface

uses
	Fgl, SysUtils,
	PNTree, PNCore, PNStack, PNTypes;

function Parse(const vInput: String; vOperators: TOperationsMap): TPNStack;

implementation

type
	TTokenList = specialize TFPGObjectList<TPNNode>;

{ Tokenize a string. Tokens still don't know what their meaning of life is }
function Tokenize(vContext: String; vOperators: TOperationsMap): TTokenList;
var
	vPart: String;
	vOp: TOperationInfo;
begin
	result := TTokenList.Create(False);
	result.Capacity := Length(vContext);

	// add all operators to the arrays
	for vOp in vOperators do begin
		vContext := vContext.Replace(vOp.OperatorName, cSpace + vOp.OperatorName + cSpace, [rfReplaceAll]);
	end;

	for vPart in vContext.Split(cSpace, TStringSplitOptions.ExcludeEmpty) do begin;
		// TODO: ExcludeEmpty not fully woring?
		if vPart <> String.Empty then begin
			if IsOperator(vPart, vOperators) then
				result.Add(TPNNode.Create(MakeItem(TOperatorName(vPart))))
			else
				result.Add(TPNNode.Create(MakeItem(vPart)));
		end;
	end;
end;

{ Transforms prepared TTokenList into Polish notation }
function TransformTokenList(vTokens: TTokenList; vOperators: TOperationsMap): TPNNode;

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
				vNode.OperationInfo := GetOperationInfoByOperator(vNode.Item.OperatorName, vOperators);

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
function Parse(const vInput: String; vOperators: TOperationsMap): TPNStack;
var
	vTokens: TTokenList;
	vNode: TPNNode;
begin
	vTokens := Tokenize(vInput, vOperators);
	vNode := TransformTokenList(vTokens, vOperators);

	result := TPNStack.Create;
	while vNode <> nil do begin
		result.Push(vNode.Item);
		vNode := vNode.NextInorder();
	end;

	vTokens.Free();
end;

end.

