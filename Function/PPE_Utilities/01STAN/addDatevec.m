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
vElemMax(3) = eomday(vDate(1)+floor(vDate(1,2)./12),mod(vDate(1,2),12));  

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