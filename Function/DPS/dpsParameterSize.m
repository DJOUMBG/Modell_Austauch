function sSize = dpsParameterSize(vVar)
% DPSPARAMETERSIZE create a size string according DIVe definitions.
% Dimensions are separated by commata.
% Scalars are only desrcribed by '1' (not '1,1').
%
% Syntax:
%   sSize = dpsParameterSize(vVar)
%
% Inputs:
%   vVar - numeric value (mxn) [or any variable - however not specified in
%          DIVe]
%
% Outputs:
%   sSize - string with DIVe variable dimension definition 
%
% Example: 
%   sSize = dpsParameterSize(5.6789)
%   sSize = dpsParameterSize(rand(3,5))
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-07-25

% get size of variable
nSize = size(vVar);

% corrections on MATLAB nomenclature
%scalar
if max(nSize) == 1
    nSize = 1;
end

% build string
sSize = regexprep(num2str(nSize),' +',',');
return