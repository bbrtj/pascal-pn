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

		procedure SetStack(Stack: TPNStack);

	public
		constructor Create;
		destructor Destroy; override;

		procedure ImportString(const Exported: String);
		function ExportString(): String;

		procedure DefineVariable(const Variable: String; Number: TNumber);
		procedure ClearVariables();

		procedure ParseString(const InputString: String);
		function GetResult(): TNumber;

		function Help(): String;

		property Stack: TPNStack read FCurrentStack;
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
procedure TPN.SetStack(Stack: TPNStack);
begin
	FCurrentStack.Free;
	FCurrentStack := Stack;
end;

{ Imports a string using TPNStack }
procedure TPN.ImportString(const Exported: String);
begin
	self.SetStack(TPNStack.FromString(Exported));
end;

{ Exports a the TPNStack to a string }
function TPN.ExportString(): String;
begin
	result := FCurrentStack.ToString();
end;

{ Defines a new variable for the calculations }
procedure TPN.DefineVariable(const Variable: String; Number: TNumber);
begin
	FVariableMap.AddOrSetData(ParseVariable(Variable), Number);
end;

{ Removes all defined variables for the calculation }
procedure TPN.ClearVariables();
begin
	FVariableMap.Clear();
end;

{ Parses a string via PNParser }
procedure TPN.ParseString(const InputString: String);
begin
	self.SetStack(Parse(InputString));
end;

{ Calculates the result using PNCalculator }
function TPN.GetResult(): TNumber;
begin
	if (FCurrentStack = nil) or FCurrentStack.Empty then
		raise Exception.Create('Nothing to calculate');

	result := Calculate(FCurrentStack, FVariableMap);
end;

function TPN.Help(): String;
begin
	result := TOperationInfo.Help();
end;

end.

