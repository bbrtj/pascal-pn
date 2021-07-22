unit PNParser;

{$mode objfpc}{$H+}{$J-}

{
	Code responsible for transforming a string into a PN stack
}

interface

uses
	Fgl, SysUtils, StrUtils,
	PNCore, PNStack, PNTypes;

function Parse(const input: String; const operators: TOperationsMap): TPNStack;

implementation

{ TToken class definition }
type
	TToken = class
		private
			_value: String;
			procedure SetValue(const value: String);
		public
			constructor Create(const value: String);
			property Value: String read _value write SetValue;
	end;

	TTokenList = specialize TFPGObjectList<TToken>;

constructor TToken.Create(const value: String);
begin
	SetValue(value);
end;

procedure TToken.SetValue(const value: String);
begin
	_value := value;
end;

{ TOperatorToken class definition }
type
	TOperatorToken = class(TToken)
		private
			_operator: TOperationInfo;

		public
			constructor Create(const &operator: TOperationInfo);
			property &Operator: TOperationInfo read _operator write _operator;
	end;

constructor TOperatorToken.Create(const &operator: TOperationInfo);
begin
	inherited Create(&operator.&operator);
	self.&Operator := &operator;
end;

{ TSyntaxToken class definition }
type
	TSyntaxTokenType = (sttGroupStart, sttGroupEnd);

	TSyntaxToken = class(TToken)
		private
			const
				bracketOpen = '(';
				bracketClose = ')';

			var
				_syntax: TSyntaxTokenType;

			procedure SetSyntax(const syntax: TSyntaxTokenType);
		public
			constructor Create(const syntax: TSyntaxTokenType);
			property Syntax: TSyntaxTokenType read _syntax write SetSyntax;
	end;

constructor TSyntaxToken.Create(const syntax: TSyntaxTokenType);
begin
	self.Syntax := syntax;
end;

procedure TSyntaxToken.SetSyntax(const syntax: TSyntaxTokenType);
begin
	_syntax := syntax;

	if syntax = sttGroupStart then
		Value := bracketOpen
	else if syntax = sttGroupEnd then
		Value := bracketClose
	else
		raise Exception.Create('Invalid token type');
end;

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
	list := TTokenList.Create(True);

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
	type
		TContext = specialize TFPGObjectList<TTokenList>;

	{ Recursively transform standard notation }
	function TransformRecursive(tillBrace: Boolean = False): TTokenList;
	var
		lastOperation: ^TOperationInfo;
		sublist: TTokenList;
		nested: TContext;

		currentToken: TToken;
		currentIndex: Integer;
		moveCounter: Integer;

	begin
		result := TTokenList.Create(False);
		nested := TContext.Create(True);
		lastOperation := nil;

		while tokens.Count > 0 do begin
			currentToken := tokens.First;

			if currentToken is TOperatorToken then begin
				currentIndex := result.Count - 1;

				if (lastOperation <> nil)
					and (lastOperation^.priority > (currentToken as TOperatorToken).&Operator.priority)
				then begin
					for currentIndex := currentIndex downto 0 do begin
						if (result[currentIndex] is TOperatorToken)
							and ((currentToken as TOperatorToken).&Operator.priority
								>= (result[currentIndex] as TOperatorToken).&Operator.priority)
						then
							break;
					end;
				end;

				if currentIndex < 0 then
					currentIndex := 0;

				lastOperation := Addr((currentToken as TOperatorToken).&Operator);
				result.Insert(currentIndex, tokens.Extract(currentToken));
			end

			else if currentToken is TSyntaxToken then begin
				case (currentToken as TSyntaxToken).Syntax of

					sttGroupStart: begin
						result.Add(tokens.Extract(currentToken));
						sublist := TransformRecursive(True);

						nested.Add(sublist);
					end;

					sttGroupEnd: begin
						tokens.Extract(currentToken);
						tillBrace := not tillBrace;
						break;
					end;
				end;

			end

			else begin
				if Length(currentToken.Value) = 0 then
					tokens.Remove(currentToken)
				else
					result.Add(tokens.Extract(currentToken));
			end;
		end;

		if tillBrace then
			raise Exception.Create('Unmatched braces');

		currentIndex := 0;
		while currentIndex < result.Count do begin
			currentToken := result[currentIndex];

			// any TSyntaxTokens left have to be replaced with associated TTokenLists
			// (late insertion of nested contexts)
			if currentToken is TSyntaxToken then begin
				result.Remove(currentToken);
				sublist := nested.Extract(nested[0]);
				result.AddList(sublist);

				moveCounter := currentIndex;
				while currentIndex < moveCounter + sublist.Count do begin
					result.Move(result.Count - sublist.Count + (currentIndex - moveCounter), currentIndex);
					Inc(currentIndex);
				end;
			end
			else
				Inc(currentIndex);
		end;

		nested.Free();
	end;

begin
	result := TransformRecursive();

	tokens.Free();
end;

{ Transforms a TToken (from TTokenList) into TItem (to be pushed onto TPNStack) }
function GetItemFromToken(const token: TToken): TItem;
var
	value: TNumber;
begin
	if token is TOperatorToken then
		result := MakeItem(TOperator(token.Value))
	else if TryStrToFloat(token.Value, value) then
		result := MakeItem(value)
	else if IsValidIdent(token.Value) then
		result := MakeItem(TVariable(token.Value))
	else
		raise Exception.Create('Invalid token ' + token.Value);
end;

{ Parses the entire calculation }
function Parse(const input: String; const operators: TOperationsMap): TPNStack;
var
	tokens: TTokenList;
	token: TToken;
begin
	tokens := Tokenize(input, operators);
	tokens := TransformTokenList(tokens);

	result := TPNStack.Create;
	for token in tokens do begin
		result.Push(GetItemFromToken(token));
	end;

	// Free all tokens, which may have multiple pointers to the same memory
	while tokens.Count > 0 do begin
		token := tokens.First;
		while tokens.Remove(token) <> -1 do;
		token.Free();
	end;

	tokens.Free();
end;

end.
