unit PNTree;

{$mode objfpc}{$H+}{$J-}

{
	Tree implementation for parsing the standard notation
}

interface

uses
	PNCore, PNTypes;

type
	PPNNode = ^TPNNode;

	TPNNode = class
	strict private
		FItem: TItem;
		FOpInfo: TOperationInfo;

		FLeft: TPNNode;
		FRight: TPNNode;
		FParent: TPNNode;

		procedure SetLeft(vNode: TPNNode);
		procedure SetRight(vNode: TPNNode);
	public
		constructor Create(vItem: TItem);
		destructor Destroy; override;

		function OperationPriority(): Byte;
		function OperationType(): TOperationType;

		function NextInorder(): TPNNode;

		property Item: TItem read FItem;
		property Left: TPNNode read FLeft write SetLeft;
		property Right: TPNNode read FRight write SetRight;
		property Parent: TPNNode read FParent write FParent;
		property OperationInfo: TOperationInfo read FOpInfo write FOpInfo;
	end;

implementation

{}
constructor TPNNode.Create(vItem: TItem);
begin
	FItem := vItem;
	FLeft := nil;
	FRight := nil;
	FParent := nil;
end;

{}
destructor TPNNode.Destroy;
begin
	// do not free the parent
	FLeft.Free();
	FRight.Free();
end;

{ Set the left node (plus its parent) }
procedure TPNNode.SetLeft(vNode: TPNNode);
begin
	if FLeft <> nil then
		FLeft.Parent := nil;
	FLeft := vNode;
	vNode.Parent := self;
end;

{ Set the right node (plus its parent) }
procedure TPNNode.SetRight(vNode: TPNNode);
begin
	if FRight <> nil then
		FRight.Parent := nil;
	FRight := vNode;
	vNode.Parent := self;
end;

{ Get the priority of an operation stored }
function TPNNode.OperationPriority(): Byte;
begin
	result := FOpInfo.Priority;
end;

{ Get the type of an operation stored }
function TPNNode.OperationType(): TOperationType;
begin
	result := FOpInfo.OperationType;
end;


{ Traverse the tree Inorder }
function TPNNode.NextInorder(): TPNNode;
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

