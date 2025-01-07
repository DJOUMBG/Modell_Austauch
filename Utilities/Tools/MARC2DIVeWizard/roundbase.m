function Y = roundbase(varargin)
% roundbase(X,digits) - function overload of MATLAB build-in function to
% enable rounding to a defined precision in scaled systems.
% 
% Input variables:
% X         - value to be rounded
% digits    - number of valid decimals for rounding [optional]
% Factor    - number of valid decimals for rounding [optional]
% 
% Output variables:
% Y         - rounded value
% 
% Example Calls
% Y = roundbase([12.345 9.8975]) % gives [12 10] >> standard MATLAB behavior of rounding to integers
% Y = roundbase([12.345 9.8975],1,0.001) 

if nargin < 2
    Y = round(varargin{1});
else
    digits = round(varargin{2}); % viable digits for value
    Factor = varargin{3}; % integer element factor of scaled value
    Y = round(varargin{1}./Factor).*Factor;
    Y = roundd(Y,digits);
end
return
