unit PN;

{$mode objfpc}{$H+}{$J-}

interface

uses
	SysUtils,
	PNCalculator, PNParser, PNCore, PNStack, PNTypes;

type

	TPN = class
		protected
			operationsMap: TOperationsMap;
			currentStack: TPNStack;

		public
			constructor Create;
			destructor Destroy; override;

		procedure ParseString(const input: String);
		procedure ImportString(const exported: String);
		function GetResult(): TNumber;

	end;

implementation

{}
constructor TPN.Create;
begin
	inherited;
	operationsMap := GetOperationsMap();
end;

{}
destructor TPN.Destroy;
begin
	FreeAndNil(operationsMap);

	if currentStack <> nil then
		FreeAndNil(currentStack);

	inherited;
end;

{ Parses a string via PNParser }
procedure TPN.ParseString(const input: String);
begin
end;

{ Imports a string using TPNStack }
procedure TPN.ImportString(const exported: String);
begin
	currentStack := TPNStack.FromString(exported);
end;

{ Calculates the result using PNCalculator }
function TPN.GetResult(): TNumber;
begin
	result := Calculate(currentStack, [], operationsMap);
end;

end.
