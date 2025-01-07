function spsUxxWrite(xSource,sFile)
% SPSUXXWRITE write the content of the first subset of a Morphix/Uniread
% structure to an ASCII-File in UXX/tdl file format.
%
% Syntax:
%   spsUxxWrite(xSource,sFile)
%
% Inputs:
%   xSource - structure with according Morhpix/Uniread 
%     sFile - string with filepath
%
% Outputs:
%
% Example: 
%   spsUxxWrite(xSource,sFile)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-04-10

% compile header string
sSeparator = ';';

% generate header of data block
sHeaderName = '';
sHeaderUnit = '';
sHeaderType = '';
for nIdxSignal = 1:numel(xSource(1).subset(1).data.name)
    if nIdxSignal <= numel(xSource(1).subset(1).data.name)
        sHeaderName = [sHeaderName xSource(1).subset(1).data.name{nIdxSignal} ...
            sSeparator]; %#ok
    else
        sHeaderName = [sHeaderName 'Signal' num2str(nIdxSignal,'%3.0f') sSeparator]; %#ok
    end
    sHeaderUnit = [sHeaderUnit  sSeparator]; %#ok
    sHeaderType = [sHeaderType  sSeparator]; %#ok
end
sHeaderName = [sHeaderName(1:end-numel(sSeparator)) '\r\n'];
sHeaderUnit = [sHeaderUnit(1:end-numel(sSeparator)) '\r\n'];
sHeaderType = [sHeaderType(1:end-numel(sSeparator)) '\r\n'];

% create format string for data fprintf operation
sFormat = ['% 16.5f' sSeparator];
for nIdxSignal = 1:numel(xSource(1).subset(1).data.name)-1
    sFormat = [sFormat '% 16.10e' sSeparator]; %#ok
end
sFormat = [sFormat(1:end-numel(sSeparator)) '\r\n'];

% open file
hFile = fopen(sFile,'w');

% print header
fprintf(hFile,'UXX-BEGIN\r\n');

% loop over all attributes
for nIdxAttr = 1:numel(xSource(1).subset(1).attribute.name)
    if ischar(xSource(1).subset(1).attribute.value{nIdxAttr}) 
        if ismember(xSource(1).subset(1).attribute.value{nIdxAttr},{'$1','$2','$3'})
            % print string
            fprintf(hFile,'%s = %s\r\n',...
                xSource(1).subset(1).attribute.name{nIdxAttr},...
                xSource(1).subset(1).attribute.value{nIdxAttr});
        else
            % print string
            fprintf(hFile,'%s = "%s"\r\n',...
                xSource(1).subset(1).attribute.name{nIdxAttr},...
                xSource(1).subset(1).attribute.value{nIdxAttr});
        end
    elseif isnumeric(xSource(1).subset(1).attribute.value{nIdxAttr}) 
        % print number
        fprintf(hFile,'%s = %g\r\n',...
            xSource(1).subset(1).attribute.name{nIdxAttr},...
            xSource(1).subset(1).attribute.value{nIdxAttr});
    else
        fprintf(1,['Warning: spsUxxWrite omitted Attribute "%s" due to ' ...
            'an invalid value type\r\n'],...
            xSource(1).subset(1).attribute.name{nIdxAttr});
    end
end

% print end of header
fprintf(hFile,'UXX-END\r\n');

% write header, unit and type
fprintf(hFile,sHeaderName);
fprintf(hFile,sHeaderUnit);
fprintf(hFile,sHeaderType);

% write data
for nIdxLine = 1:size(xSource(1).subset(1).data.value,1)
    fprintf(hFile,sFormat,xSource(1).subset(1).data.value(nIdxLine,:));
end

% close ASCII file
fclose(hFile);
return
