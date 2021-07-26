unit PNCore;

{$mode objfpc}{$H+}{$J-}

{
	Core of the PN system, which happens to be the definition of available operators
}

interface

uses
	Math, SysUtils,
	PNStack, PNTypes;

type
	TSyntaxType = (stGroupStart, stGroupEnd);

	TOperationHandler = function (const stack: TPNNumberStack): TNumber;
	TOperationType = (otSyntax, otInfix);
	TOperationInfo = record
		&operator: TOperator;
		handler: TOperationHandler;
		priority: Byte;
		operationType: TOperationType;
		syntax: TSyntaxType;
	end;

	TOperationsMap = Array of TOperationInfo;


function GetOperationsMap(): TOperationsMap; inline;
function IsOperator(const op: String; const map: TOperationsMap): Boolean; inline;
function GetOperationInfoByOperator(const op: TOperator; const map: TOperationsMap; const noSyntax: Boolean = False): TOperationInfo;

implementation

{ Get the next argument from the stack, raise an exception if not possible }
function NextArg(const stack: TPNNumberStack): TNumber; inline;
begin
	if stack.Empty() then
		raise Exception.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := stack.Pop();
end;

{ Handler for + }
function OpAddition(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result += NextArg(stack);
end;

{ Handler for - }
function OpSubstraction(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result -= NextArg(stack);
end;

{ Handler for * }
function OpMultiplication(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result *= NextArg(stack);
end;

{ Handler for / }
function OpDivision(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result /= NextArg(stack);
end;

{ Handler for ^ }
function OpPower(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result := result ** NextArg(stack);
end;

{ Handler for % }
function OpModulo(const stack: TPNNumberStack): TNumber;
begin
	result := NextArg(stack);
	result := FMod(result, NextArg(stack));
end;

{ Creates a new TOperationInfo }
function MakeInfo(const &operator: TOperator; const handler: TOperationHandler; const priority: Byte): TOperationInfo;
begin
	result.&operator := &operator;
	result.handler := handler;
	result.priority := priority;
	result.operationType := otInfix;
end;

function MakeSyntax(const symbol: TOperator; const value: TSyntaxType): TOperationInfo;
begin
	result.operationType := otSyntax;
	result.&operator := symbol;
	result.syntax := value;
end;

function GetOperationsMap(): TOperationsMap;
begin
	result := TOperationsMap.Create(
		MakeInfo('+', @OpAddition, 1),
		MakeInfo('-', @OpSubstraction, 1),
		MakeInfo('*', @OpMultiplication, 2),
		MakeInfo('/', @OpDivision, 2),
		MakeInfo('%', @OpModulo, 2),
		MakeInfo('^', @OpPower, 3),
		MakeSyntax('(', stGroupStart),
		MakeSyntax(')', stGroupEnd)
	);
end;

function IsOperator(const op: String; const map: TOperationsMap): Boolean;
var
	info: TOperationInfo;

begin
	for info in map do begin
		if info.&operator = op then
			Exit(True);
	end;

	result := False;
end;

function GetOperationInfoByOperator(const op: TOperator; const map: TOperationsMap; const noSyntax: Boolean = False): TOperationInfo;
var
	info: TOperationInfo;

begin
	for info in map do begin
		if (info.&operator = op) and ((not noSyntax) or (info.operationType <> otSyntax)) then
			Exit(info);
	end;

	raise Exception.Create('Invalid operator ' + op);
end;

end.
