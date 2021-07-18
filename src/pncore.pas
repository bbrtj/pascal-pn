unit PNCore;

interface

uses
	fgl,
	PNStack, PNTypes;

type
	TOperationHandler = function (const a, b: TNumber): TNumber;
	TOperationsMap = specialize TFPGMap<TOperator, TOperationHandler>;

implementation

end.
