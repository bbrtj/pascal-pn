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
	list: TTokenList;

	{ Insert one list into the index of the other, replacing a given index }
	function ReplaceInList(const toAdd: TTokenList; atIndex: Integer): Integer;
	var
		token: TToken;
	begin
		list.Delete(atIndex);

		for token in toAdd do begin
			list.Insert(atIndex, token);
			Inc(atIndex);
		end;

		toAdd.Free();
		result := atIndex;
	end;

	{ Divide one already split TToken into several TTokens }
	function DivideToken(const splitData: TStringArray; const withToken: TToken): TTokenList;
	var
		sublist: TTokenList;
		index: Integer;

	begin
		sublist := TTokenList.Create(False);

		for index := Low(splitData) to High(splitData) - 1 do begin
			sublist.Add(TToken.Create(splitData[index]));
			sublist.Add(withToken);
		end;

		sublist.Add(TToken.Create(splitData[High(splitData)]));

		result := sublist;
	end;

	{ Do the splitting }
	procedure SplitTokens(const currentOperator: TToken);
	var
		current: TToken;
		currentIndex: Integer;

	begin
		currentIndex := 0;

		while currentIndex < list.Count do begin
			current := list[currentIndex];

			if AnsiContainsStr(current.Value, currentOperator.Value) then
				currentIndex := ReplaceInList(
					DivideToken(current.Value.Split([currentOperator.Value]), currentOperator),
					currentIndex
				)
			else
				Inc(currentIndex);
		end;
	end;

var
	op: TOperationInfo;
	stt: TSyntaxTokenType;
	part: String;

begin
	list := TTokenList.Create(False);

	for part in context.split(' ') do
		list.Add(TToken.Create(part));

	for stt in TSyntaxTokenType do
		SplitTokens(TSyntaxToken.Create(stt));

	for op in operators do
		SplitTokens(TOperatorToken.Create(op));

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
end;

end.
