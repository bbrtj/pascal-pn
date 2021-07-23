unit PNTree;

{$mode objfpc}{$H+}{$J-}

{
	Tree implementation for parsing the standard notation
}

interface

uses
	PNToken, PNCore;

type
	PPNNode = ^TPNNode;

	TPNNode = class
		private
			FToken: TToken;

			FLeft: TPNNode;
			FRight: TPNNode;
			FParent: TPNNode;

			procedure SetLeft(const node: TPNNode);
			procedure SetRight(const node: TPNNode);
		public
			constructor Create(const token: TToken);
			destructor Destroy; override;

			function IsOperation(): Boolean;
			function OperationPriority(): Byte;
			function OperationType(): TOperationType;

			property token: TToken read FToken write FToken;
			property left: TPNNode read FLeft write SetLeft;
			property right: TPNNode read FRight write SetRight;
			property parent: TPNNode read FParent write FParent;

			function NextInorder(): TPNNode;
	end;

implementation

{}
constructor TPNNode.Create(const token: TToken);
begin
	FToken := token;
	FLeft := nil;
	FRight := nil;
	FParent := nil;
end;

{}
destructor TPNNode.Destroy;
begin
	// do not free the token or the parent
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

{ Check whether the node stores an operation }
function TPNNode.IsOperation(): Boolean;
begin
	result := FToken is TOperatorToken;
end;

{ Get the priority of an operation stored }
function TPNNode.OperationPriority(): Byte;
begin
	result := (FToken as TOperatorToken).&Operator.priority;
end;

{ Get the type of an operation stored }
function TPNNode.OperationType(): TOperationType;
begin
	result := (FToken as TOperatorToken).&Operator.operationType;
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
