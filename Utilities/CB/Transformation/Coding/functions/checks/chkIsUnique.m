function bValid = chkIsUnique(A)
% CHKISUNIQUE checks if elements in A are unique.
%
% Syntax:
%   bValid = chkIsUnique(A)
%
% Inputs:
%   A - various (nxm): scalar, vector or matrix with elements  
%
% Outputs:
%   bValid - boolean (1x1): flag if A has unique elements (true) or not (false) 
%
% Example: 
%   bValid = chkIsUnique(A)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2022-12-15

%% check if A has unique values

% reshape so row vector
A = reshape(A,1,numel(A));

% analyse unique
[~,nUnq,nRef] = unique(A);

% check is unique, if length of nUnq and nRef are equal
if isequal(numel(nUnq),numel(nRef))
    bValid = true;
else
    bValid = false;
end

return