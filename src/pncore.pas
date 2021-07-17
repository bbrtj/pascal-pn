unit PNCore;

interface

uses
	fgl,
	PNStack, PNTypes;

type
	TOperationHandler = function (a: TNumber; b: TNumber): TNumber;
	TOperationsMap = specialize TFPGMap<TOperator, TOperationHandler>;

implementation

end.
