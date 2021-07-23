unit PNToken;

{$mode objfpc}{$H+}{$J-}

{
	Types of tokens, which are the results of parsing a string
}

interface

uses
	SysUtils,
	PNCore, PNTypes;

type
	{ TToken class definition }
	TToken = class
		private
			Fvalue: String;
			procedure SetValue(const value: String);
		public
			constructor Create(const value: String);
			property Value: String read Fvalue write SetValue;
	end;

	{ TOperatorToken class definition }
	TOperatorToken = class(TToken)
		private
			Foperator: TOperationInfo;

		public
			constructor Create(const &operator: TOperationInfo);
			property &Operator: TOperationInfo read Foperator write Foperator;
	end;

	TSyntaxTokenType = (sttGroupStart, sttGroupEnd);

	{ TSyntaxToken class definition }
	TSyntaxToken = class(TToken)
		private
			const
				bracketOpen = '(';
				bracketClose = ')';

			var
				Fsyntax: TSyntaxTokenType;

			procedure SetSyntax(const syntax: TSyntaxTokenType);
		public
			constructor Create(const syntax: TSyntaxTokenType);
			property Syntax: TSyntaxTokenType read Fsyntax write SetSyntax;
	end;

function GetItemFromToken(const token: TToken): TItem;

implementation

{}
constructor TToken.Create(const value: String);
begin
	SetValue(value);
end;

{ Set textual value of a token }
procedure TToken.SetValue(const value: String);
begin
	Fvalue := value;
end;

{}
constructor TOperatorToken.Create(const &operator: TOperationInfo);
begin
	inherited Create(&operator.&operator);
	self.&Operator := &operator;
end;

{}
constructor TSyntaxToken.Create(const syntax: TSyntaxTokenType);
begin
	self.Syntax := syntax;
end;

{ Set syntax value of a token }
procedure TSyntaxToken.SetSyntax(const syntax: TSyntaxTokenType);
begin
	Fsyntax := syntax;

	if syntax = sttGroupStart then
		Value := bracketOpen
	else if syntax = sttGroupEnd then
		Value := bracketClose
	else
		raise Exception.Create('Invalid token type');
end;

{ Transforms a TToken into TItem (to be pushed onto TPNStack) }
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

end.

