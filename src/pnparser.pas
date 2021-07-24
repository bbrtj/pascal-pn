unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack
}

interface

uses
	Fgl, SysUtils, StrUtils,
	PNTree, PNToken, PNCore, PNStack, PNTypes;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;

implementation

type
	TElementType = (etSyntax, etOperator);
	TElementInfo = record
		elementType: TElementType;
		syntax: TSyntaxInfo;
		&operator: TOperationInfo;
	end;

function MakeElementInfo(const info: TSyntaxInfo): TElementInfo;
begin
	result.elementType := etSyntax;
	result.syntax := info;
end;

function MakeElementInfo(const info: TOperationInfo): TElementInfo;
begin
	result.elementType := etOperator;
	result.&operator := info;
end;

function MakeTokenFromElementInfo(const info: TElementInfo): TToken;
begin
	case info.elementType of
		etSyntax: result := TSyntaxToken.Create(info.syntax);
		etOperator: result := TOperatorToken.Create(info.&operator);
	end;
end;

type
	TTokenList = specialize TFPGObjectList<TToken>;

{ Tokenize a string. Tokens still don't know what their meaning of life is }
function Tokenize(const context: String; const operators: TOperationsMap): TTokenList;
var
	lastChar: SizeInt;

	function GetSubstringToken(const first: SizeInt; last: SizeInt): TToken;
	begin
		if last > lastChar then
			last := lastChar;

		result := TToken.Create(context.Substring(first, last - first).Trim());
	end;

var
	list: TTokenList;

	op: TOperationInfo;
	si: TSyntaxInfo;
	part: String;

	splitInfo: array of TElementInfo;
	splitElements: array of String;

	lastIndex: SizeInt;
	index: SizeInt;
	match: SizeInt;

begin
	list := TTokenList.Create(True);
	lastChar := Length(context);
	list.Capacity := lastChar;

	// calculate and set the required length
	index := Ord(High(TSyntaxType)) + 1 + Length(operators);
	SetLength(splitInfo, index);
	SetLength(splitElements, index);
	index := 0;

	// add all syntax elements to the arrays
	for si in GetSyntaxMap() do begin
		splitInfo[index] := MakeElementInfo(si);
		splitElements[index] := si.symbol;
		index += 1;
	end;

	// add all operators to the arrays
	for op in operators do begin
		splitInfo[index] := MakeElementInfo(op);
		splitElements[index] := op.&operator;
		index += 1;
	end;

	lastIndex := 0;
	while True do begin
		index := context.IndexOfAny(splitElements, lastIndex, lastChar - lastIndex, match);

		if index < 0 then begin
			list.Add(GetSubstringToken(lastIndex, lastChar));
			break;
		end
		else begin
			if index > 0 then
				list.Add(GetSubstringToken(lastIndex, index));

			list.Add(MakeTokenFromElementInfo(splitInfo[match]));
			lastIndex := index + Length(splitElements[match]);
		end;
	end;

	result := list;
end;

{ Transforms prepared TTokenList into Polish notation }
function TransformTokenList(const tokens: TTokenList): TTokenList;

	procedure AddNode(const node, lastOperation: TPNNode; const root: PPNNode);
	begin
		if lastOperation <> nil then begin
			if (lastOperation.OperationType() = otInfix) and (lastOperation.right = nil) then
				lastOperation.right := node
			else
				raise Exception.Create(
					Format('Unexpected %S (operator %S)', [node.token.Value, lastOperation.token.Value])
				);
		end
		else if root^ = nil then
			root^ := node
		else
			raise Exception.Create(Format('Unexpected %S', [node.token.Value]));
	end;

	{ Recursively transform standard notation into a tree }
	function MakeTree(var index: Word; inBraces: Boolean = False): TPNNode;
	var
		lastOperation: TPNNode;
		currentRoot: TPNNode;
		node: TPNNode;
		tmp: TPNNode;

		currentToken: TToken;

	begin
		lastOperation := nil;
		currentRoot := nil;

		while index < tokens.Count do begin
			currentToken := tokens[index];

			if currentToken is TOperatorToken then begin
				node := TPNNode.Create(currentToken);

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
			end

			else if currentToken is TSyntaxToken then begin
				index += 1;

				case (currentToken as TSyntaxToken).Syntax.value of
					stGroupStart: begin
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
				if Length(currentToken.Value) > 0 then begin
					node := TPNNode.Create(currentToken);
					AddNode(node, lastOperation, @currentRoot);
				end;
			end;

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
	resultTree := MakeTree(index);
	result := TTokenList.Create(False);
	result.Capacity := tokens.Capacity;

	treeNode := resultTree;
	while treeNode <> nil do begin
		result.Add(treeNode.token);
		treeNode := treeNode.NextInorder();
	end;

	resultTree.Free();
end;

{ Parses the entire calculation }
function Parse(const input: String; const operators: TOperationsMap): TPNStack;
var
	tokens: TTokenList;
	sortedTokens: TTokenList;
	token: TToken;
begin
	tokens := Tokenize(input, operators);
	sortedTokens := TransformTokenList(tokens);

	result := TPNStack.Create;
	for token in sortedTokens do begin
		result.Push(GetItemFromToken(token));
	end;

	tokens.Free();
	sortedTokens.Free();
end;

end.
