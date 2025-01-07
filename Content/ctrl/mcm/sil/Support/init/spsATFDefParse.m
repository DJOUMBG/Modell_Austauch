function xElem = spsATFDefParse(sFile)
% SPSATFDEFPARSE parse ATF definition files for data model, units or
% quantities.
%
% Syntax:
%   xElem = spsATFDefParse(sFile)
%
% Inputs:
%   sFile - string 
%
% Outputs:
%   xElem - structure (1xm) with fields of defined application elements, 
%           which contain
%           - in case of application elements/data model parsing 
%             a cell (nx2) contains all defined attributes within the element 
%           - in case of multiple instances of same element are defined
%             a structure vector (1xn) with fields of all attribute value
%             pairs 
%             
%   xInst - structure vector (1xn) with fields of defined attributes
%
% Example: 
%   xElem = spsATFDefParse('Units.txt')
%   xElem = spsATFDefParse('Quantities.txt')
%   xElem = spsATFDefParse('DataModel.txt')
%
% See also: structInit, verLessThanMATLAB
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-09-04

% input check
if ~exist(sFile,'file')
    sFileWhich = which(sFile);
    if isempty(sFileWhich)
        error('spsWriteATF:sourceFileNotFound',...
            'spsWriteATF - the specified source file is not available: %s \n',sFile);
    else
        sFile = sFileWhich;
    end
end

% init output
xElem = struct();

% read file by line
nFid = fopen(sFile,'r');
if verLessThanMATLAB('8.4.0')
    ccLine = textscan(nFid,'%s','delimiter','\n','whitespace','','bufsize',65536); %#ok<BUFSIZE> 
else
    ccLine = textscan(nFid,'%s','delimiter','\n','whitespace','');
end
fclose(nFid);
cLine = strtrim(ccLine{1});

% parse file
nMode = 0;
for nIdxLine = 1:numel(cLine)
    if isempty(cLine{nIdxLine}) || strcmp(cLine{nIdxLine}(1:2),'//')
        % omit line
    else % parse
        switch nMode
            case 0 % search new element or instance
                if strcmp(cLine{nIdxLine}(1:8),'APPLELEM')
                    % new application element starts
                    sElem = regexp(cLine{nIdxLine}(10:end),'^\w+','match','once');
                    nMode = 1;
                    nAttribute = 0;
                    cAttribute = cell(1000,2);
                elseif strcmp(cLine{nIdxLine}(1:8),'INSTELEM')
                    % new instance starts
                    sElem = regexp(cLine{nIdxLine}(10:end),'^\w+','match','once');
                    nMode = 2;
                    if isfield(xElem,sElem)
                        nInstance = numel(xElem.(sElem)) + 1;
                    else
                        nInstance = 1;
                    end
                else
                    % omit line
                end
                
            case 1 % parse new attribute for application element
                if strcmp(cLine{nIdxLine}(1:8),'APPLATTR')
                    nAttribute = nAttribute + 1;
                    sName = regexp(cLine{nIdxLine}(10:end),'^\w+','match','once');
                    sDataType = regexp(cLine{nIdxLine}(10+numel(sName):end),...
                        '(?<=DATATYPE )\w+','match','once');
                    cAttribute(nAttribute,:) = {sName sDataType};
                elseif strcmp(cLine{nIdxLine}(1:11),'ENDAPPLELEM')
                    % end parsing and create element
                    xElem.(sElem) = cAttribute(1:nAttribute,:);
                    nMode = 0;
                end
                
            case 2 % parse new instance
                if strcmp(cLine{nIdxLine}(1:min(11,numel(cLine{nIdxLine}))),'ENDINSTELEM')
                    % end parsing of instance
                    nMode = 0;
                else
                    % add field to currect instance structure
                    % parse attribute and value
                    sName = regexp(cLine{nIdxLine},'^\w+','match','once');
                    sValue = regexp(cLine{nIdxLine}(1+numel(sName):end),...
                        '(?<=\s*\=\s*"?)[^";\s]+','match','once');
                    
                    % check for numeric value
                    nCharFirst = double(sValue(1));
                    if nCharFirst > 47 && nCharFirst < 58
                        vValue = str2double(sValue);
                        if ~isnan(vValue)
                            sValue = vValue;
                        end
                    end
                    
                    % assign value
                    xElem.(sElem)(nInstance).(sName) = sValue;
                end
        end % switch mode
    end % if worth parsing
end % for 
return