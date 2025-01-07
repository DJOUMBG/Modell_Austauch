function Y = roundd(varargin)
% roundd(X,digits) - function overload of MATLAB build-in function to
% enable rounding to a defined decimal precision.
% 
% Input variables:
% X         - value to be rounded
% digits    - number of valid decimals for rounding [optional]
% 
% Output variables:
% Y         - rounded value
% 
% Example Calls
% Y = roundd([12.345 9.8975]) % gives [12 10] >> standard MATLAB behavior of rounding to integers
% Y = roundd([12.345 9.8975],1) 

if nargin < 2
    Y = round(varargin{1});
else
    digits = round(varargin{2});
    Y = round(varargin{1}.*10^digits).*10^(-1*digits);
end
return
