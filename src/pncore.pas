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

	TOperationHandler = function (stack: TPNNumberStack): TNumber;
	TOperationType = (otSyntax, otInfix);
	TOperationInfo = record
		OperatorName: TOperatorName;
		Handler: TOperationHandler;
		Priority: Byte;
		OperationType: TOperationType;
		Syntax: TSyntaxType;
	end;

	TOperationsMap = Array of TOperationInfo;

var
	PNOperationsMap: TOperationsMap;

function IsOperator(const vOp: String; vMap: TOperationsMap): Boolean;
function GetOperationInfoByOperator(const vOp: TOperatorName; vMap: TOperationsMap; vNoSyntax: Boolean = False): TOperationInfo;

implementation

{ Get the next argument from the stack, raise an exception if not possible }
function NextArg(vStack: TPNNumberStack): TNumber;
begin
	if vStack.Empty() then
		raise Exception.Create('Invalid Polish notation: stack is empty, cannot get operand');

	result := vStack.Pop();
end;

{ Handler for + }
function OpAddition(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result += NextArg(vStack);
end;

{ Handler for - }
function OpSubstraction(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result -= NextArg(vStack);
end;

{ Handler for * }
function OpMultiplication(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result *= NextArg(vStack);
end;

{ Handler for / }
function OpDivision(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result /= NextArg(vStack);
end;

{ Handler for ^ }
function OpPower(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := result ** NextArg(vStack);
end;

{ Handler for % }
function OpModulo(vStack: TPNNumberStack): TNumber;
begin
	result := NextArg(vStack);
	result := FMod(result, NextArg(vStack));
end;

{ Creates a new TOperationInfo }
function MakeInfo(vOperator: TOperatorName; vHandler: TOperationHandler; vPriority: Byte): TOperationInfo;
begin
	result.OperatorName := vOperator;
	result.Handler := vHandler;
	result.Priority := vPriority;
	result.OperationType := otInfix;
end;

function MakeSyntax(const vSymbol: TOperatorName; vValue: TSyntaxType): TOperationInfo;
begin
	result.OperationType := otSyntax;
	result.OperatorName := vSymbol;
	result.Syntax := vValue;
end;

function IsOperator(const vOp: String; vMap: TOperationsMap): Boolean;
var
	vInfo: TOperationInfo;
begin
	result := False;

	for vInfo in vMap do begin
		if vInfo.OperatorName = vOp then begin
			result := True;
			break;
		end;
	end;
end;

function GetOperationInfoByOperator(const vOp: TOperatorName; vMap: TOperationsMap; vNoSyntax: Boolean = False): TOperationInfo;
var
	vInfo: TOperationInfo;
begin
	for vInfo in vMap do begin
		if (vInfo.OperatorName = vOp) and ((not vNoSyntax) or (vInfo.OperationType <> otSyntax)) then
			Exit(vInfo);
	end;

	raise Exception.Create('Invalid operator ' + vOp);
end;

initialization
	PNOperationsMap := [
		MakeInfo('+', @OpAddition, 1),
		MakeInfo('-', @OpSubstraction, 1),
		MakeInfo('*', @OpMultiplication, 2),
		MakeInfo('/', @OpDivision, 2),
		MakeInfo('%', @OpModulo, 2),
		MakeInfo('^', @OpPower, 3),
		MakeSyntax('(', stGroupStart),
		MakeSyntax(')', stGroupEnd)
	];

end.

