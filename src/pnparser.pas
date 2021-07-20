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

	TTokenList = specialize TFPGList<TToken>;

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
			destructor Destroy; override;
			property &Operator: POperationInfo read _operator write _operator;
	end;

constructor TOperatorToken.Create(const &operator: TOperationInfo);
begin
	self.&Operator := @&operator;
	inherited Create(self.&Operator^.&operator);
end;

destructor TOperatorToken.Destroy;
begin
	FreeAndNil(_operator);
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
		list[atIndex].Free;
		list.Delete(atIndex);

		for token in toAdd do begin
			list.Insert(atIndex, token);
			Inc(atIndex);
		end;

		result := atIndex;
	end;

	{ Divide one already split TToken into several TTokens }
	function DivideToken(const splitData: TStringArray; const withToken: TToken): TTokenList;
	var
		sublist: TTokenList;
		index: Integer;

	begin
		sublist := TTokenList.Create;

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
		sublist := TTokenList.Create;

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
	list := TTokenList.Create;
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

	FreeAndNil(operatorsList);
	result := list;
end;

{ Parses the entire calculation }
function Parse(const input: String; const operators: TOperationsMap): TPNStack;
begin
	result := TPNStack.Create;
end;

end.
