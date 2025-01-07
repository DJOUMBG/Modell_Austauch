function xSubset = spsUnireadMVACorrection(xSubset)
% SPSUNIREADMVACORRECTION correction of DIVeMB uniread results for MVA
% import functions:
% - ensure RECZEIT channel with timestampm in [s]
% - correct the "MessEnde" attribute based on timestamp and "MessBeginn"
%   attribute
%
% Syntax:
%   xSubset = spsUnireadMVACorrection(xSubset)
%
% Inputs:
%   xSubset - structure with fields: 
%
% Outputs:
%   xSubset - structure with fields: 
%
% Example: 
%   xSubset = spsUnireadMVACorrection(xSubset)

% See also: spsATFWrite, spsUniplot2MVA
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-09-04


% sort data for RECZEIT as first channel
bRT = ismember(xSubset.data.name,'RECZEIT');
if ~any(bRT) % RECZEIT channel was not found
    bRT = ismember(xSubset.data.name,{'time','Time'});
    if any(bRT)
        nRT = find(bRT);
        xSubset.data.name{nRT(1)} = 'RECZEIT'; % set first hit to RECZEIT
        bRT = false(size(bRT)); % ensure correct boolean for sorting
        bRT(nRT) = true;
    else
        error('vtUniplot2MVA:noRECZEIT',...
            'Uniplot to MVA conversion failed - MVA requires a data channel RECZEIT!')
    end
end
if any(bRT) % RECZEIT channel was found or patched
    % resort channel name and data
    xSubset.data.name = [xSubset.data.name(bRT) xSubset.data.name(~bRT)];
    xSubset.data.value = [xSubset.data.value(:,bRT) xSubset.data.value(:,~bRT)];
end

% add SYSRECZEIT
bSys = ismember(xSubset.data.name,'SYSRECZEIT');
if ~any(bSys)
    xSubset.data.name =  [xSubset.data.name(1:sum(bRT)) {'SYSRECZEIT'} ...
                          xSubset.data.name(sum(bRT)+1:end)];
    xSubset.data.value = [xSubset.data.value(:,1:sum(bRT)) xSubset.data.value(:,1).*1000 ...
                          xSubset.data.value(:,sum(bRT)+1:end)];
end

% create correct attribute MessEnde
vMessBeginn = datevec(num2str(getAttribute('MessBeginn',xSubset.attribute)),'yyyymmddHHMMSS'); 
vTimePeriod = xSubset.data.value(end,1); % assumption: timestamp is first data column
vMessEnde = addDatevec(vMessBeginn,[zeros(1,5) vTimePeriod]);
xSubset.attribute = setAttribute('MessEnde',datestr(vMessEnde,'yyyymmddHHMMSS'),xSubset.attribute);
return

% =========================================================================

function vNum = datevec2num(vDate)
% DATEVEC2NUM create a number representing a datevector with seconds as the
% base order (format: yyyymmddHHMMSS)
%
% Syntax:
%   vNum = datevec2num(vDate)
%
% Inputs:
%   vDate - vector (nx6) with date vectors [yyyy mm dd HH MM SS]
%
% Outputs:
%   vNum - vector (nx1) with number in format [yyyymmddHHMMSS]
%
% Example: 
%   vNum = datevec2num(vDate)

% vNum = zeros(size(vDate,1),1);
vNum = vDate(:,1) * 1e10;
vNum = vNum + vDate(:,2) * 1e8;
vNum = vNum + vDate(:,3) * 1e6;
vNum = vNum + vDate(:,4) * 1e4;
vNum = vNum + vDate(:,5) * 1e2;
vNum = vNum + vDate(:,6);
return

% =========================================================================

function vDate = addDatevec(vDate1,vDate2)
% ADDDATEVEC adds two date vector notations of [yyyy mm dd HH MM SS].
%
% Syntax:
%   vDate = addDatevec(vDate1,vDate2)
%
% Inputs:
%   vDate1 - vector (1x6) of format [yyyy mm dd HH MM SS]
%   vDate2 - vector (1x6) of format [yyyy mm dd HH MM SS] 
%
% Outputs:
%   vDate - vector (1x1) [yyyy mm dd HH MM SS]
%
% Example: 
%   vDate = addDatevec(vDate1,vDate2)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-06-22

% define maximum entry for datevec (entry 3 for days in month 
vElemMax = [inf 12 30 24 60 60];  

% add date vectors
vDate = vDate1 + vDate2;

% get correct maximum days for month
if vDate(1,2) > 12
    vDate(1,2) = mod(vDate(1,2),12);
    vDate(1,1) = vDate(1,1)+floor(vDate(1,2)./12);
end
vElemMax(3) = eomday(vDate(1,1),vDate(1,2));  

% propagate exceeding values to next vector element
for nIdxElem = numel(vElemMax):-1:2
    if nIdxElem == 3 && any(vDate(:,3))>58
        warning('addDatevec:insecureDayCountPropagation',['The calculation '...
            'of new month from days includes a span of more than one month '...
            '- the day might not be correct due to weak "day per month" '...
            'implemenation, when spanning multiple months.'])
    end
    vDate(:,nIdxElem-1) = vDate(:,nIdxElem-1) + floor(vDate(:,nIdxElem)./vElemMax(nIdxElem));
    vDate(:,nIdxElem) = mod(vDate(:,nIdxElem),vElemMax(nIdxElem));
end
return

% =========================================================================

function value = getAttribute(sName,xAttribute)
% GETATTRIBUTE get an attribute value by an attribute name string from a
% Morphix data structure subset attribute part.
%
% Syntax:
%   value = getAttribute(sName,xAttribute)
%
% Inputs:
%        sName - string with attribute name
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Outputs:
%   value - real or string with attribute value
%
% Example: 
%   value = getAttribute(sName,xAttribute)

nHit = find(ismember(xAttribute.name,sName));
if numel(nHit) > 0
    value = xAttribute.value{nHit(1)};
else
    value = [];
end
return

% =========================================================================

function xAttribute = setAttribute(sName,vValue,xAttribute)
% GETATTRIBUTE set an attribute value by an attribute name string from a
% Morphix data structure subset attribute part.
%
% Syntax:
%   xAttribute = setAttribute(sName,vValue,xAttribute)
%
% Inputs:
%        sName - string with attribute name
%       vValue - string or number with attribute value
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Outputs:
%   xAttribute - structure with fields: 
%       .name  - cell with strings containing attribute names
%       .value - cell with strings or values containing attribute values
%
% Example: 
%   xAttribute = setAttribute('MessEnde',20150622083634,xAttribute)

nHit = find(ismember(xAttribute.name,sName));
if numel(nHit) > 0
    xAttribute.value{nHit(1)} = vValue;
else
    warning('setAttribute:noAttribute',['Attribute for setting parameter not found in structure: ' sName])
end
return