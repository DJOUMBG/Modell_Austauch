function hlxConfigVersionCorrect(cPath)
% HLXCONFIGVERSIONCORRECT remove wrong string entries and unresolved pathes
% from versionId values. Cleanup function used after incomplete versionId
% resolve operations, when server connection fails.
%
% Syntax:
%   hlxConfigVersionCorrect(cPath)
%
% Inputs:
%   cPath - cell (1xn) with strings of configurations or 
%           string with configuration to be corrected
%
% Outputs:
%
% Example: 
%   hlxConfigVersionCorrect('ConfigA.xml')
%   hlxConfigVersionCorrect({'ConfigA.xml','ConfigB.xml})
%
% See also: hlxConfigVersionCorrect
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-11-16

% remove wrong string entries and unresolved pathes from versionId values

if ischar(cPath)
    cPath = {cPath};
end

for nIdxPath = 1:numel(cPath)
    % get xml files of directory
    cFile = dirPattern(cPath{nIdxPath},'*.xml','file');
    
    bCorrect = false;
    for nIdxFile = 1:numel(cFile)
        xTree = dsxRead(fullfile(cPath{nIdxPath},cFile{nIdxFile}));
        
        for nIdxSetup = 1:numel(xTree.Configuration.ModuleSetup)
            % Module
            for nIdxItem = 1:numel(xTree.Configuration.ModuleSetup(nIdxSetup).Module)
                vTest = str2double(xTree.Configuration.ModuleSetup(nIdxSetup).Module(nIdxItem).versionId);
                if isnan(vTest)
                    bCorrect = true;
                    xTree.Configuration.ModuleSetup(nIdxSetup).Module(nIdxItem).versionId = '';
                end
            end
            % DataSet
            for nIdxItem = 1:numel(xTree.Configuration.ModuleSetup(nIdxSetup).DataSet)
                vTest = str2double(xTree.Configuration.ModuleSetup(nIdxSetup).DataSet(nIdxItem).versionId);
                if isnan(vTest)
                    bCorrect = true;
                    xTree.Configuration.ModuleSetup(nIdxSetup).DataSet(nIdxItem).versionId = '';
                end
            end
            % SupportSet
            if isfield(xTree.Configuration.ModuleSetup(nIdxSetup),'SupportSet')
                for nIdxItem = 1:numel(xTree.Configuration.ModuleSetup(nIdxSetup).SupportSet)
                    vTest = str2double(xTree.Configuration.ModuleSetup(nIdxSetup).SupportSet(nIdxItem).versionId);
                    if isnan(vTest)
                        bCorrect = true;
                        xTree.Configuration.ModuleSetup(nIdxSetup).SupportSet(nIdxItem).versionId = '';
                    end
                end % for SupportSet
            end % if SupportSet
        end % for Module Setup
        
        if bCorrect
            dsxWrite(fullfile(cPath{nIdxPath},cFile{nIdxFile}),xTree)
        end
    end % for file

end % for path
return
