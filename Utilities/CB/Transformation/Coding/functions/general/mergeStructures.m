function xStructRes = mergeStructures(xStructA,xStructB)
% MERGESTRUCTURES merge fields of two structures, without overwriting field
%  valus of A with B. Also order fields alphabetical in resulting structure.
%
% Syntax:
%   xStructRes = mergeStructures(xStructA,xStructB)
%
% Inputs:
%   xStructA - structure with fields
%   xStructB - structure with fields
%
% Outputs:
%   xStructRes - structure with merged fields
%
% Example: 
%   xStructRes = mergeStructures(xStructA,xStructB)
%
%
% Test:
%  A.a = 1; A.b = 2; A.c = 3; B.A = 2; B.d = 4;
%  xStructRes = mergeStructures(A,B);
%
%  A = struct([]); B.A = 2; B.d = 4;
%  xStructRes = mergeStructures(A,B);
%
%  A.a = 1; A.b = 2; A.c = 3; B = struct([]);
%  xStructRes = mergeStructures(A,B);
%
%  A = struct([]); B = struct([]);
%  xStructRes = mergeStructures(A,B);
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-11-06


%% check field names

% get fieldnames of A
cFieldsA = fieldnames(xStructA);

% get fieldnames of B
cFieldsB = fieldnames(xStructB);

% get difference of fields between A and B
bNotInA = not(ismember(cFieldsB,cFieldsA));

% get fields in B that are not in A
cMissingFieldsInA = cFieldsB(bNotInA);


%% add missing fields

% init output structure
if isempty(xStructA)
    xStructRes = xStructB;
    cMissingFieldsInA = {};
else
    xStructRes = xStructA;
end

% add missing fields in A from B
for nField=1:numel(cMissingFieldsInA)
    sFieldname = cMissingFieldsInA{nField};
    xStructRes.(sFieldname) = xStructB.(sFieldname);
end

% get fieldnames of structure
cFieldnames = fieldnames(xStructRes);

% get fieldname sort order
[~,nSortOrder] = sort(lower(cFieldnames));

% sorted fieldnames
cFieldnames = cFieldnames(nSortOrder);

% sort structure by fieldnames
xStructRes = orderfields(xStructRes,cFieldnames);

return