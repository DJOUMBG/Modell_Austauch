function spsSilDcmCorrection(cFile)
% SPSSILDCMCORRECTION correction file for MARC DCM export files, which have
% an illegal ST/Y tag within "STUETZSTELLENVERTEILUNG" sections. This needs
% to be replaced by ST/X in these sections.
%
% Syntax:
%   spsSilDcmCorrection(cFile)
%
% Inputs:
%   cFile - string with filepath of DCM file
% Outputs:
%
% Example: 
%   spsSilDcmCorrection(cFile)
%
% Subfunctions: getVectorElementGreater
%
% See also: verLessThanMATLAB
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-06-14

% input check
if nargin < 1
        [sFile,sPath] = uigetfile( ...
        {'*.dcm','DCM files (*.dcm)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Open DCM File',...
        'MultiSelect','off');
    if isequal(sFile,0) % user chosed cancel in file selection popup
        return
    else
        cFile = fullfile(sPath,sFile);
    end
end
% ensure cell
if ischar(cFile)
    cFile = {cFile};
end

for nIdxFile = 1:numel(cFile)
    % patch folder inputs, which contain a single dcm-file
    if exist(cFile{nIdxFile},'file')~=2
        if exist(cFile{nIdxFile},'dir')==7 % is a folder
            cDcm = dirPattern(cFile{nIdxFile},'*.dcm','file');
            if numel(cDcm) == 1
                % use single dcm-file inside folder instead of folder
                cFile{nIdxFile} = fullfile(cFile{nIdxFile},cDcm{1});
            end % if just one dcm in folder
        end % if folder
    end % if not file
    
    % read DCM as ASCII file
    nFid = fopen(cFile{nIdxFile},'r');
    sHead = fgetl(nFid);
    if numel(sHead) < 15
        % correction still necessary
        frewind(nFid);
        if verLessThanMATLAB('8.4.0')
            ccLine = textscan(nFid,'%s','delimiter','\n','Whitespace','','bufsize',65536);
        else
            ccLine = textscan(nFid,'%s','delimiter','\n','Whitespace','');
        end
        fclose(nFid);
    else
        % DCM file was already corrected by spsSilDcmCorrection
        fclose(nFid);
        return
    end
    cLine = ccLine{1};
    
    % determine start and end of section STUETZSTELLENVERTEILUNG
    nStart = find(~cellfun(@isempty,regexp(cLine,'^STUETZSTELLENVERTEILUNG','once')));
    nEndAll = find(~cellfun(@isempty,regexp(cLine,'^END','once')));
    nIdxEnd = arrayfun(@(x)find(x<nEndAll,1,'first'),nStart);
    nEnd = nEndAll(nIdxEnd);
    
    % replace ST/Y entry by ST/X entry within section STUETZSTELLENVERTEILUNG
    for nIdxSection = 1:numel(nStart)
        cLine(nStart(nIdxSection):nEnd(nIdxSection)) = regexprep(...
            cLine(nStart(nIdxSection):nEnd(nIdxSection)),...
            'ST/Y','ST/X');
    end
    if strcmp(getenv('username'),'rafrey5')
        fprintf(1,'Correction on %i entries.\n',numel(nStart));
    end
    
    % add marker space (to prevent repeated handling)
    cLine{1} = [cLine{1} ' '];
    
    % secure old file
    [sPath,sName] = fileparts(cFile{nIdxFile});
    bStatus = 0;
    nRetry = 0;
    while ~bStatus && nRetry < 10
        [bStatus,sMsg] = movefile(cFile{nIdxFile},fullfile(sPath,[sName,'.org']));
        pause(0.1);
        nRetry = nRetry + 1;
    end
    if nRetry > 9
        fprintf(2,'movefile failed and reached the retry limit: \n%s\n',sMsg);
    end
    
    % write DCM file
    nFid = fopen(cFile{nIdxFile},'w');
    for nIdxLine = 1:numel(cLine)
        fprintf(nFid,'%s\n',cLine{nIdxLine});
    end
    fclose(nFid);
end % for all files
return
