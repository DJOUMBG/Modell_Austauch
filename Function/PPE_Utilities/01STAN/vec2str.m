function str = vec2str(vData)
% VEC2STR converts a vector into a comma-separated number string
%
% Syntax:
%   str = vec2str(vData)
%
% Inputs:
%   vData - vector (1x1) of integer or double with size(1xn) or (nx1)
%
% Outputs:
%   str - string of vector values separated by commata
%
% Example: 
%   str = vec2str([1,2.2,3])
%
% See also: strGlue
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2007-06-01

% input check
nSize = size(vData);
if length(nSize)>2
    error('vec2str:input','only vectors allowed as input - no multidimensional input');
elseif min(nSize)>1
    error('vec2str:input','only vectors allowed as input - no matrices allowed as input');
end

% create string
if isnumeric(vData)
   cData = arrayfun(@num2str,vData,'UniformOutput',false);
   str = strGlue(cData,',');
else
    str = [];
end
return