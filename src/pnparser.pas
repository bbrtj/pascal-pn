unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack
}

interface

uses
	Fgl, SysUtils,
	PNTree, PNCore, PNStack, PNTypes;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;

implementation

type
	TTokenList = specialize TFPGObjectList<TPNNode>;

{ Tokenize a string. Tokens still don't know what their meaning of life is }
function Tokenize(context: String; const operators: TOperationsMap): TTokenList;
var
	list: TTokenList;

	part: String;
	op: TOperationInfo;

begin
	list := TTokenList.Create(False);
	list.Capacity := Length(context);

	// add all operators to the arrays
	for op in operators do begin
		context := context.Replace(op.&operator, space + op.&operator + space, [rfReplaceAll]);
	end;

	for part in context.Split(space, TStringSplitOptions.ExcludeEmpty) do begin;
		// TODO: ExcludeEmpty not fully woring?
		if part <> String.Empty then begin
			if IsOperator(part, operators) then
				list.Add(TPNNode.Create(MakeItem(TOperator(part))))
			else
				list.Add(TPNNode.Create(MakeItem(part)));
		end;
	end;

	result := list;
end;

{ Transforms prepared TTokenList into Polish notation }
function TransformTokenList(const tokens: TTokenList; const operators: TOperationsMap): TPNNode;

	procedure AddNode(const node, lastOperation: TPNNode; const root: PPNNode); inline;
	begin
		if lastOperation <> nil then begin
			if (lastOperation.OperationType() = otInfix) and (lastOperation.right = nil) then
				lastOperation.right := node
			else
				raise Exception.Create(
					Format('Unexpected value %S (operator %S)', [GetItemValue(node.item), lastOperation.item.&operator])
				);
		end
		else if root^ = nil then
			root^ := node
		else
			raise Exception.Create(Format('Unexpected value %S', [GetItemValue(node.item)]));
	end;

	{ Recursively transform standard notation into a tree }
	function MakeTree(var index: Word; inBraces: Boolean = False): TPNNode;
	var
		lastOperation: TPNNode;
		currentRoot: TPNNode;
		node: TPNNode;
		tmp: TPNNode;

	begin
		lastOperation := nil;
		currentRoot := nil;

		while index < tokens.Count do begin
			node := tokens[index];

			if node.item.itemType = itOperator then begin
				node.operationInfo := GetOperationInfoByOperator(node.item.&operator, operators);

				if node.OperationType() = otSyntax then begin
					case node.operationInfo.syntax of
						stGroupStart: begin
							index += 1;
							node := MakeTree(index, True);
							AddNode(node, lastOperation, @currentRoot);
						end;

						stGroupEnd: begin
							inBraces := not inBraces;
							break;
						end;
					end;
				end

				else begin
					while (lastOperation <> nil) and (lastOperation.OperationPriority() >= node.OperationPriority()) do
						lastOperation := lastOperation.parent;

					if lastOperation = nil then begin
						node.left := currentRoot;
						currentRoot := node;
					end

					else begin
						tmp := lastOperation.right;
						lastOperation.right := node;
						node.left := tmp;
					end;

					lastOperation := node;
				end;
			end

			else
				AddNode(node, lastOperation, @currentRoot);

			index += 1;
		end;

		if inBraces then
			raise Exception.Create('Unmatched braces');

		result := currentRoot;
	end;

var
	resultTree: TPNNode;
	treeNode: TPNNode;
	index: Word;

begin
	index := 0;
	result := MakeTree(index);
end;

{ Parses the entire calculation }
function Parse(const input: String; const operators: TOperationsMap): TPNStack;
var
	tokens: TTokenList;
	node: TPNNode;
begin
	tokens := Tokenize(input, operators);
	node := TransformTokenList(tokens, operators);

	result := TPNStack.Create;
	while node <> nil do begin
		result.Push(node.item);
		node := node.NextInorder();
	end;

	tokens.Free();
end;

end.
