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

function OpAddition(const a, b: TNumber): TNumber;
begin
	result := a + b;
end;

function OpSubstraction(const a, b: TNumber): TNumber;
begin
	result := a - b;
end;

function OpMultiplication(const a, b: TNumber): TNumber;
begin
	result := a * b;
end;

function OpDivision(const a, b: TNumber): TNumber;
begin
	result := a / b;
end;

function OpPower(const a, b: TNumber): TNumber;
begin
	result := a ** b;
end;

function OpModulo(const a, b: TNumber): TNumber;
begin
	result := FMod(a, b);
end;

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
