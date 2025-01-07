function Y = roundv(varargin)
% roundv(X,digits) - function overload of MATLAB build-in function to
% enable rounding to a defined decimal precision, while respecting real
% data type definition. So rounding is only applied to exponential
% notation.
% 
% Input variables:
% X         - value to be rounded
% digits    - number of valid decimals for rounding [optional]
% 
% Output variables:
% Y         - rounded value
% 
% Example Calls
% Y = roundv(1.23456789e-6,3) 

if nargin < 2
    Y = round(varargin{1});
else
    digits = round(varargin{2});
    nExp = floor(log10(varargin{1}));
    Y = round(varargin{1}.*10^digits.*10.^(-1.*nExp)).*10^(-1*digits).*10^nExp;
end
return
