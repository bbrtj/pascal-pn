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
	POperationInfo = ^TOperationInfo;
	TOperatorToken = class(TToken)
		private
			_operator: POperationInfo;

		public
			constructor Create(const &operator: TOperationInfo);
			property &Operator: POperationInfo read _operator write _operator;
	end;

constructor TOperatorToken.Create(const &operator: TOperationInfo);
begin
	self.&Operator := @&operator;
	inherited Create(self.&Operator^.&operator);
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

	{ Get token list for operators, which can be used to split other tokens }
	function GetOperatorTokenList(): TTokenList;
	var
		sublist: TTokenList;
		op: TOperationInfo;

	begin
		sublist := TTokenList.Create(False);

		sublist.Add(TSyntaxToken.Create(sttGroupStart));
		sublist.Add(TSyntaxToken.Create(sttGroupEnd));

		for op in operators do
			sublist.Add(TOperatorToken.Create(op));

		result := sublist;
	end;

var
	current: TToken;
	currentIndex: Integer;

	operatorsList: TTokenList;
	currentOperator: TToken;

begin
	list := TTokenList.Create(True);
	list.Add(TToken.Create(AnsiReplaceStr(context, ' ', '')));
	operatorsList := GetOperatorTokenList();

	for currentOperator in operatorsList do begin
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

	operatorsList.Free();
	result := list;
end;

{ Transforms prepared TTokenList into Polish notation }
function TransformTokenList(const tokens: TTokenList): TTokenList;

	{ Recursively transform standard notation }
	function TransformRecursive(): TTokenList;
	var
		lastOperation: POperationInfo;
		sublist: TTokenList;

		currentToken: TToken;
		currentIndex: Integer;

	begin
		result := TTokenList.Create(False);

		while tokens.First <> nil do begin
			currentToken := tokens.First;

			if currentToken is TOperatorToken then begin
				currentIndex := result.Count - 1;

				if (lastOperation <> nil)
					and (lastOperation^.priority > (currentToken as TOperatorToken).&Operator^.priority)
				then begin
					for currentIndex := currentIndex downto 0 do begin
						if (result[currentIndex] is TOperatorToken)
							and ((currentToken as TOperatorToken).&Operator^.priority
								>= (result[currentIndex] as TOperatorToken).&Operator^.priority)
						then
							break;
					end;
				end;

				result.Insert(currentIndex, tokens.Extract(currentToken));
				lastOperation := (currentToken as TOperatorToken).&Operator;
			end

			else if currentToken is TSyntaxToken then begin

				case (currentToken as TSyntaxToken).Syntax of
					sttGroupStart: begin
						sublist := TransformRecursive();
						result.AddList(sublist);
						sublist.Free();
					end;
					sttGroupEnd: break;
				end;
			end

			else begin
				if Length(currentToken.Value) = 0 then
					tokens.Remove(currentToken)
				else
					result.Add(tokens.Extract(currentToken));
			end;
		end;
	end;

begin
	result := TransformRecursive();
	result.FreeObjects := True;

	if tokens.Count > 0 then
		raise Exception.Create('Invalid notation passed');

	tokens.Free();
end;

{ Transforms a TToken (from TTokenList) into TItem (to be pushed onto TPNStack) }
function GetItemFromToken(const token: TToken): TItem;
var
	value: TNumber;
begin
	if token.ClassType = TOperatorToken then
		result := MakeItem(TOperator(token.Value))
	else if TryStrToFloat(token.Value, value) then
		result := MakeItem(value)
	else
		result := MakeItem(TVariable(token.Value));
	// TODO: Check if variable contains only a-z
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

	tokens.Free();
end;

end.
