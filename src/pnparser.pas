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
	stt: TSyntaxTokenType;
	part: String;

	splitTokens: array of TToken;
	splitElements: array of String;

	lastIndex: SizeInt;
	index: SizeInt;
	match: SizeInt;

begin
	list := TTokenList.Create(False);
	lastChar := Length(context);

	// calculate and set the required length
	index := Ord(High(TSyntaxTokenType)) + 1 + Length(operators);
	SetLength(splitTokens, index);
	SetLength(splitElements, index);
	index := 0;

	// add all syntax elements to the arrays
	for stt in TSyntaxTokenType do begin
		splitTokens[index] := TSyntaxToken.Create(stt);
		splitElements[index] := splitTokens[index].Value;
		index += 1;
	end;

	// add all operators to the arrays
	for op in operators do begin
		splitTokens[index] := TOperatorToken.Create(op);
		splitElements[index] := splitTokens[index].Value;
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

			list.Add(splitTokens[match]);
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
	function MakeTree(var index: Integer; inBraces: Boolean = False): TPNNode;
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

				case (currentToken as TSyntaxToken).Syntax of
					sttGroupStart: begin
						node := MakeTree(index, True);
						AddNode(node, lastOperation, @currentRoot);
					end;

					sttGroupEnd: begin
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
	index: Integer;

begin
	index := 0;
	resultTree := MakeTree(index);
	result := TTokenList.Create(False);

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

	// Free all tokens, which may have multiple pointers to the same memory
	while tokens.Count > 0 do begin
		token := tokens.First;
		while tokens.Remove(token) <> -1 do;
		token.Free();
	end;

	tokens.Free();
	sortedTokens.Free();
end;

end.
