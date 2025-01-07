function sId = dpsFcnIdCreate(sName,sUser,nIndex)
% DPSFCNIDCREATE create a aplphanumeric, case insensitive id of specified
% configuration name, user name, index numer (for scripted high frequency
% IDs) and current time.
%
% Syntax:
%   sId = dpsFcnIdCreate(sName,sUser,nIndex)
%   sId = dpsFcnIdCreate(sName,sUser)
%
% Inputs:
%    sName - string with configuration/filename
%    sUser - string with userID
%   nIndex - integer (1x1) for high frequency IDs by script generation
%
% Outputs:
%      sId - string with 9 digit ID
%
% Example: 
%   sId = dpsFcnIdCreate('OM934STC_ED3312_130kW_BB3892_WHTC_Ph2_TMAuto_ivc_vt_m06_53_03','rafrey5',0)
%
% Subfunctions: dpsFcnChecksumCreate, dpsFcnIdbDec2Base
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2015-08-20

% check input
if nargin < 3
    nIndex = 0;
end

% get checksums
nCheckName = dpsFcnChecksumCreate(sName);
nCheckUser = dpsFcnChecksumCreate(sUser);
nPrefix = nCheckName + nCheckUser + nIndex;
sId1 = dpsFcnIdbDec2Base(nPrefix,3);

% get datetime ID
nTime = datevec(now);
nTime(1) = nTime(1) - 2015; % year basis is 2015
nTime(6) = floor(nTime(6)); % floor of seconds
nTimeId = nTime * [32140800,2678400,8640,3600,60,1]';

% modify time with index of script base generation
nTimeId = nTimeId + nIndex;
sId2 = dpsFcnIdbDec2Base(nTimeId,6);

% combine ID parts
sId = [sId1 sId2];
return

% =========================================================================

function sId = dpsFcnIdbDec2Base(nNumber,nNumel)
% DPSFCNIDBDEC2BASE create a string with a number based on 36 elements
% [0-9a-z] and the specified default length.
%
% Syntax:
%   sId = dpsFcnIdbDec2Base(nNumber,nNumel)
%
% Inputs:
%   nNumber - integer (1x1) 
%    nNumel - integer (1x1) 
%
% Outputs:
%   sId - string 
%
% Example: 
%   sId = dpsFcnIdbDec2Base(1545245425,6)

% initialize output
sId = '000000';
sId = sId(1:min(numel(sId),nNumel));

% ID cell for digit assignment
cId = {'0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g',...
       'h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x',...
       'y','z'};

% division factor for base36 space up to 6 digits (36^6 = 2.17e9)
nLimit = int64([1,36,1296,46656,1679616,60466176,2176782336]);

% create base36 number
nMod = nNumber;
for nIdx = min(numel(nLimit),nNumel):-1:1
    nDigit = idivide(int64(nMod),nLimit(nIdx),'floor'); % get current digit
    nDigit = mod(nDigit,36); % prevent buffer overflow
    nMod = mod(nMod,nLimit(nIdx)); % prepare rest for next iteration
    sId(nIdx) = cId{nDigit+1}; % get base36 element character
end
return

% =========================================================================

function nChecksum = dpsFcnChecksumCreate(sString)
% DPSFCNCHECKSUMCREATE create a numeric checksum of a string in the decimal
% system from a string conversion to digit space [0-9a-z], where special
% characters are the maximum value (36).
%
% Syntax:
%   nChecksum = dpsFcnChecksumCreate(sString)
%
% Inputs:
%   sString - string 
%
% Outputs:
%   nChecksum - integer (1x1) 
%
% Example: 
%   nChecksum = dpsFcnChecksumCreate(sString)

% convert to numbers
nString = double(lower(sString));

% get number digits
bNumber = nString > 47 & nString < 58;
% get character digits 
bChar = nString > 96 & nString < 123;
% get special characters
bRest = ~bNumber & ~bChar;

% create base10 checksum
nChecksum = sum(nString(bNumber)-47) + sum(nString(bChar)-96+10) + sum(bRest)*36;
return

