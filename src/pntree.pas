unit PNTree;

{$mode objfpc}{$H+}{$J-}

{
	Tree implementation for parsing the standard notation
}

interface

uses
	PNBase;

type
	PPNNode = ^TPNNode;

	TPNNode = class
	strict private
		FItem: TItem;
		FGrouped: Boolean;

		FLeft: TPNNode;
		FRight: TPNNode;
		FParent: TPNNode;

		procedure SetLeft(vNode: TPNNode);
		procedure SetRight(vNode: TPNNode);
	public
		constructor Create(vItem: TItem);

		procedure FreeRecursively();
		function IsOperation(): Boolean;
		function OperationPriority(): Byte;
		function OperationType(): TOperationType;

		function NextPreorder(): TPNNode;

		property Item: TItem read FItem;
		property Left: TPNNode read FLeft write SetLeft;
		property Right: TPNNode read FRight write SetRight;
		property Parent: TPNNode read FParent write FParent;
		property Grouped: Boolean read FGrouped write FGrouped;
	end;

implementation

{}
constructor TPNNode.Create(vItem: TItem);
begin
	FItem := vItem;
	FGrouped := False;
	FLeft := nil;
	FRight := nil;
	FParent := nil;
end;

procedure TPNNode.FreeRecursively();
begin
	FLeft.Free();
	FRight.Free();
end;

{ Set the left node (plus its parent) }
procedure TPNNode.SetLeft(vNode: TPNNode);
begin
	if (FLeft <> nil) and (FLeft.Parent = self) then
		FLeft.Parent := nil;

	FLeft := vNode;
	if vNode <> nil then
		vNode.Parent := self;
end;

{ Set the right node (plus its parent) }
procedure TPNNode.SetRight(vNode: TPNNode);
begin
	if (FRight <> nil) and (FRight.Parent = self) then
		FRight.Parent := nil;

	FRight := vNode;
	if vNode <> nil then
		vNode.Parent := self;
end;

function TPNNode.IsOperation(): Boolean;
begin
	result := FItem.ItemType = itOperator;
end;

{ Get the priority of an operation stored }
function TPNNode.OperationPriority(): Byte;
begin
	result := FItem.Operation.Priority;
end;

{ Get the type of an operation stored }
function TPNNode.OperationType(): TOperationType;
begin
	result := FItem.Operation.OperationType;
end;


{ Traverse the tree Preorder }
function TPNNode.NextPreorder(): TPNNode;
var
	vLast: TPNNode;
begin
	if self.Left <> nil then
		result := self.Left
	else begin
		result := self;
		vLast := result;

		while (result <> nil) and ((result.Right = nil) or (result.Right = vLast)) do begin
			vLast := result;
			result := result.Parent;
		end;

		if result <> nil then
			result := result.Right;
	end;
end;

end.

