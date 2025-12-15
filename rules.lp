%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% General Conventions (for ASP, not from the specification) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A reference implies the reference with the parent-ReferenceTypes.
% This is generated from the nodeset via the nodeset-compiler.
%
% Examples:
% impliedRef(X,Y,references) :- ref(X,Y,references) .
% impliedRef(X,Y,nonHierarchicalReferences) :- ref(X,Y,nonHierarchicalReferences) .
% impliedRef(X,Y,references) :- ref(X,Y,nonHierarchicalReferences) .
% impliedRef(X,Y,hierarchicalReferences) :- ref(X,Y,hierarchicalReferences) .
% impliedRef(X,Y,references) :- ref(X,Y,hierarchicalReferences) .
% impliedRef(X,Y,hasChild) :- ref(X,Y,hasChild) .

%% References ref(X,Y,refType) are sometimes written in the shorthand notation
%% refType(X,Y). The "R" postfix indicates that the reference refTypeR(X,Y) can
%% be recursive (multi-hop) for the same (implied) ReferenceType.

% HasChild
hasChild(X,Y)   :- impliedRef(X,Y,hasChild) .
hasChildR(X,Y)  :- hasChild(X,Y) .
hasChildR(X,Y)  :- hasChild(X,Z), hasChildR(Z,Y) .
hasParent(X,Y)  :- hasChild(Y,X) .
hasParentR(X,Y) :- hasChildN(Y,X) .

% HasSubtype
hasSubtype(X,Y)  :- impliedRef(X,Y,hasSubtype) .
hasSubtypeR(X,Y) :- hasSubtype(X,Y) .
hasSubtypeR(X,Y) :- hasSubtype(X,Z), hasSubtypeR(Z,Y) .
subtypeOf(X,Y)   :- hasSubtype(Y,X) .
subtypeOfR(X,Y)  :- hasSubtypeR(Y,X) .

% Type-Nodes (ReferenceTypes, VariableTypes, ObjectTypes, DataTypes) are always
% a subtype of themselves. This simplifies constraints that need to be satisfied
% for a type and all its subtypes.

hasSubtype(X,Y) :- node(X, referenceTypeNode, _), X == Y .
hasSubtype(X,Y) :- node(X, dataTypeNode, _),      X == Y .
hasSubtype(X,Y) :- node(X, variableTypeNode, _),  X == Y .
hasSubtype(X,Y) :- node(X, objectTypeNode, _),    X == Y .

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Specification Part 3 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 7.2 References ReferenceType
% ----------------------------

% The References ReferenceType is an abstract ReferenceType.

:- ref(_,_,references) .

% All ReferenceTypes shall be a subtype of this base ReferenceType - either
% direct or indirect.

:- node(X, referenceTypeNode, _), not subtypeOfR(X, "i=31") .

% 7.3 HierarchicalReferences ReferenceType
% ----------------------------------------

% The HierarchicalReferences ReferenceType is an abstract ReferenceType.

:- ref(_,_,hierarchicalReferences) .

% It is not permitted to have a Property as SourceNode of a Reference of any
% subtype of this abstract ReferenceType

:- impliedRef(_,X,hasProperty), impliedRef(X,_,hierarchicalReferences) .

% It is not allowed that the SourceNode and the TargetNode of a Reference of the
% ReferenceType HierarchicalReferences are the same, that is, it is not allowed
% to have self-references using HierarchicalReferences.

:- impliedRef(X,X,hierarchicalReferences) .

% 7.4 NonHierarchicalReferences ReferenceType
% -------------------------------------------

% The NonHierarchicalReferences ReferenceType is an abstract ReferenceType

:- ref(_,_,nonHierarchicalReferences) .

% 7.5 HasChild ReferenceType
% --------------------------

% The HasChild ReferenceType is an abstract ReferenceType.

:- ref(_,_,hasChild) .

% Starting from Node “A” and only following References of the subtypes of the
% HasChild ReferenceType it shall never be possible to return to “A”.

:- hasChildR(X,X) .

% 7.6 Aggregates ReferenceType
% ----------------------------

% The Aggregates ReferenceType is an abstract ReferenceType.

:- ref(_,_,aggregates) .

% 7.7 HasComponent ReferenceType
% ------------------------------

% The TargetNode of this ReferenceType shall be a Variable, an Object or a Method

:- impliedRef(_,X,hasComponent), not node(X,variableNode,_),
   not node(X,objectNode,_), not node(X,methodNode,_) .

% By using the HasComponent Reference, the Variable is defined as DataVariable.

isDataVariable(X) :- node(X, variableNode, _), impliedRef(_,X,hasComponent) .

% If the TargetNode is a Variable, the SourceNode shall be an Object, an
% ObjectType, a DataVariable or a VariableType.

:- node(X,variableNode,_), impliedRef(Y,X,hasComponent),
   not node(Y,objectNode,_), not node(Y,objectTypeNode,_),
   not isDataVariable(Y), not node(Y,variableTypeNode,_) .

% If the TargetNode is an Object or a Method, the SourceNode shall be an Object
% or ObjectType.

:- impliedRef(X,Y,hasComponent), node(Y,objectNode,_),
   not node(X,objectNode,_), not node(X,objectTypeNode,_).
:- impliedRef(X,Y,hasComponent), node(Y,methodNode,_),
   not node(X,objectNode,_), not node(X,objectTypeNode,_).

% 7.8 HasProperty ReferenceType
% -----------------------------

% The TargetNode shall be a Variable.

:- impliedRef(_,X,hasProperty), not node(X,variableNode,_) .

% By using the HasProperty Reference, the Variable is defined as Property.

isProperty(X) :- impliedRef(_,X,hasProperty) .

% Since Properties shall not have Properties, a Property shall never be the
% SourceNode of a HasProperty Reference.

:- impliedRef(X,_,hasProperty), isProperty(X) .

% 7.8 HasOrderedComponent ReferenceType
% -------------------------------------

% 7.8 HasSubtype ReferenceType
% ----------------------------

% The SourceNode of References of this type shall be an ObjectType, a
% VariableType, a DataType or a ReferenceType and the TargetNode shall be of the
% same NodeClass as the SourceNode.

:- impliedRef(X,_,hasSubtype), not node(X,objectTypeNode,_),
   not node(X,variableTypeNode,_), not node(X,dataTypeNode,_),
   not node(X,referenceTypeNode,_) .
:- impliedRef(X,Y,hasSubtype), node(X,XType,_), node(Y,YType,_), XType != YType .

% Each ReferenceType shall be the TargetNode of at most one Reference of type
% HasSubtype.

:- node(X,_,_), node(Y,_,_), 2 {impliedRef(X,Y,hasSubtype)} .
