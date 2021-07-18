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

{
		procedure ParseString(const input: String);
		procedure ImportString(const exported: String);
		function getResult(): TNumber;
}

	end;

implementation

constructor TPN.Create;
begin
	inherited;
	operationsMap := GetOperationsMap();
end;

destructor TPN.Destroy;
begin
	FreeAndNil(operationsMap);

	if currentStack <> nil then
		FreeAndNil(currentStack);

	inherited;
end;

end.
