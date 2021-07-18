unit PNCore;

interface

uses
	fgl,
	PNStack, PNTypes;

type
	TOperationHandler = function (const a: TNumber; const b: TNumber): TNumber;
	TOperationsMap = specialize TFPGMap<TOperator, TOperationHandler>;

implementation

end.
