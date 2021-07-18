unit PNCore;

{$mode objfpc}{$H+}{$J-}

interface

uses
	fgl, Math,
	PNStack, PNTypes;

type
	TOperationHandler = function (const a, b: TNumber): TNumber;
	TOperationInfo = packed record
		handler: TOperationHandler;
		priority: Byte;
	end;

	TOperationsMap = specialize TFPGMap<TOperator, TOperationInfo>;

function GetOperationsMap(): TOperationsMap;

implementation

{ Handler for + }
function OpAddition(const a, b: TNumber): TNumber;
begin
	result := a + b;
end;

{ Handler for - }
function OpSubstraction(const a, b: TNumber): TNumber;
begin
	result := a - b;
end;

{ Handler for * }
function OpMultiplication(const a, b: TNumber): TNumber;
begin
	result := a * b;
end;

{ Handler for / }
function OpDivision(const a, b: TNumber): TNumber;
begin
	result := a / b;
end;

{ Handler for ^ }
function OpPower(const a, b: TNumber): TNumber;
begin
	result := a ** b;
end;

{ Handler for % }
function OpModulo(const a, b: TNumber): TNumber;
begin
	result := FMod(a, b);
end;

{ Creates a new TOperationInfo }
function MakeInfo(const handler: TOperationHandler; const priority: Byte): TOperationInfo;
begin
	result.handler := handler;
	result.priority := priority;
end;

function GetOperationsMap(): TOperationsMap;
begin
	result := TOperationsMap.Create;

	result.Add('+', MakeInfo(@OpAddition, 1));
	result.Add('-', MakeInfo(@OpSubstraction, 1));
	result.Add('*', MakeInfo(@OpMultiplication, 2));
	result.Add('/', MakeInfo(@OpDivision, 2));
	result.Add('%', MakeInfo(@OpModulo, 2));
	result.Add('^', MakeInfo(@OpPower, 3));
end;

end.
