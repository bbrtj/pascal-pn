unit PN;

{$mode objfpc}{$H+}{$J-}

{
	The main class used for high level access to PN routines
}

interface

uses
	SysUtils,
	PNCalculator, PNParser, PNCore, PNStack, PNTypes;

type

	TPN = class
		protected
			operationsMap: TOperationsMap;
			variableMap: TVariableMap;

			currentStack: TPNStack;
			procedure SetStack(const stack: TPNStack);

		public
			constructor Create;
			destructor Destroy; override;

			procedure ImportString(const exported: String);
			function ExportString(): String;

			procedure DefineVariable(const variable: TVariable; const number: TNumber);
			procedure ClearVariables();

			procedure ParseString(const input: String);
			function GetResult(): TNumber;

	end;

implementation

{}
constructor TPN.Create;
begin
	operationsMap := GetOperationsMap();
	variableMap := TVariableMap.Create;
end;

{}
destructor TPN.Destroy;
begin
	currentStack.Free();
	variableMap.Free();
	inherited;
end;

{ Sets a new stack with extra care to free the old one }
procedure TPN.SetStack(const stack: TPNStack);
begin
	if currentStack <> nil then
		FreeAndNil(currentStack);

	currentStack := stack;
end;

{ Imports a string using TPNStack }
procedure TPN.ImportString(const exported: String);
begin
	SetStack(TPNStack.FromString(exported));
end;

{ Exports a the TPNStack to a string }
function TPN.ExportString(): String;
begin
	result := currentStack.ToString();
end;

{ Defines a new variable for the calculations }
procedure TPN.DefineVariable(const variable: TVariable; const number: TNumber);
begin
	variableMap.Add(variable, number);
end;

{ Removes all defined variables for the calculation }
procedure TPN.ClearVariables();
begin
	variableMap.Clear();
end;

{ Parses a string via PNParser }
procedure TPN.ParseString(const input: String);
begin
	SetStack(Parse(input, operationsMap));
end;

{ Calculates the result using PNCalculator }
function TPN.GetResult(): TNumber;
begin
	if currentStack = nil then
		raise Exception.Create('Nothing to calculate');

	result := Calculate(currentStack, variableMap, operationsMap);
end;

end.

