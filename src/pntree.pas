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
		private
			FItem: TItem;
			FOpInfo: TOperationInfo;

			FLeft: TPNNode;
			FRight: TPNNode;
			FParent: TPNNode;

			procedure SetLeft(const node: TPNNode);
			procedure SetRight(const node: TPNNode);
		public
			constructor Create(const item: TItem);
			destructor Destroy; override;

			function OperationPriority(): Byte;
			function OperationType(): TOperationType;

			property item: TItem read FItem;
			property left: TPNNode read FLeft write SetLeft;
			property right: TPNNode read FRight write SetRight;
			property parent: TPNNode read FParent write FParent;
			property operationInfo: TOperationInfo read FOpInfo write FOpInfo;

			function NextInorder(): TPNNode;
	end;

implementation

{}
constructor TPNNode.Create(const item: TItem);
begin
	FItem := item;
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
procedure TPNNode.SetLeft(const node: TPNNode);
begin
	if FLeft <> nil then
		FLeft.parent := nil;
	FLeft := node;
	node.parent := self;
end;

{ Set the right node (plus its parent) }
procedure TPNNode.SetRight(const node: TPNNode);
begin
	if FRight <> nil then
		FRight.parent := nil;
	FRight := node;
	node.parent := self;
end;

{ Get the priority of an operation stored }
function TPNNode.OperationPriority(): Byte;
begin
	result := FOpInfo.priority;
end;

{ Get the type of an operation stored }
function TPNNode.OperationType(): TOperationType;
begin
	result := FOpInfo.operationType;
end;


{ Traverse the tree Inorder }
function TPNNode.NextInorder(): TPNNode;
var
	last: TPNNode;

begin
	if self.left <> nil then
		result := self.left
	else begin
		result := self;
		last := result;

		while (result <> nil) and ((result.right = nil) or (result.right = last)) do begin
			last := result;
			result := result.parent;
		end;

		if result <> nil then
			result := result.right
	end;
end;

end.
