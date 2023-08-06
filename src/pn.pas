unit PN;

{$mode objfpc}{$H+}{$J-}

{
	The main class used for high level access to PN routines
}

interface

uses
	SysUtils,
	PNCalculator, PNParser, PNStack, PNBase;

type

	TPN = class
	strict private
		FVariableMap: TVariableMap;
		FCurrentStack: TPNStack;

		procedure SetStack(vStack: TPNStack);

	public
		constructor Create;
		destructor Destroy; override;

		procedure ImportString(const vExported: String);
		function ExportString(): String;

		procedure DefineVariable(const vVariable: TVariableName; vNumber: TNumber);
		procedure ClearVariables();

		procedure ParseString(const vInput: String);
		function GetResult(): TNumber;

	end;

implementation

constructor TPN.Create;
begin
	FVariableMap := TVariableMap.Create;
end;

destructor TPN.Destroy;
begin
	FCurrentStack.Free;
	FVariableMap.Free;
	inherited;
end;

{ Sets a new stack with extra care to free the old one }
procedure TPN.SetStack(vStack: TPNStack);
begin
	FCurrentStack.Free;
	FCurrentStack := vStack;
end;

{ Imports a string using TPNStack }
procedure TPN.ImportString(const vExported: String);
begin
	self.SetStack(TPNStack.FromString(vExported));
end;

{ Exports a the TPNStack to a string }
function TPN.ExportString(): String;
begin
	result := FCurrentStack.ToString();
end;

{ Defines a new variable for the calculations }
procedure TPN.DefineVariable(const vVariable: TVariableName; vNumber: TNumber);
begin
	FVariableMap.AddOrSetData(vVariable, vNumber);
end;

{ Removes all defined variables for the calculation }
procedure TPN.ClearVariables();
begin
	FVariableMap.Clear();
end;

{ Parses a string via PNParser }
procedure TPN.ParseString(const vInput: String);
begin
	self.SetStack(Parse(vInput));
end;

{ Calculates the result using PNCalculator }
function TPN.GetResult(): TNumber;
begin
	if (FCurrentStack = nil) or FCurrentStack.Empty then
		raise Exception.Create('Nothing to calculate');

	result := Calculate(FCurrentStack, FVariableMap);
end;

end.

