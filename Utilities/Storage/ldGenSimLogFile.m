function ldGenSimLogFile(resultFileName)
% ldGenSimLogFile generate simulation logging result file
% Description:
%   newLDYN simTools
%   The whole base workspace (including the logging data) is stored to the result file
%   <resultFileName>.mat
%   Only essential parameter and logging data is stored to the reduced result file
%   <resultFileName>_red.mat
%
% Syntax:
%   ldGenSimLogFile(resultFileName)
%
% Inputs:
%     resultFileName - result file name including path
%
% Outputs:
%
% Example:
%   ldGenSimLogFile('c:\test')
%
% See also: 
%
% change history:
% 12.06.2015, RN:
% - -v7.3 option added to support large logout objects
% 06.08.2015, RN:
% - merged from DAI repository (file://emea.corpdir.net/e019/PRJ/TG/FCplatform/500_newLDYN_SimPlatform/newLDYN_SimulationTechnology_svn/branches/debuggingRound4@310)
%   - save with v7.3 format only if required
% 19.08.2019, RN:
% - reduced logging result file added (.._red.mat)

% Author: R. Neddenriep, Berner&Mattner Systemtechnik GmbH
% Date: 12/2014  

%% ------------- BEGIN CODE --------------

if evalin('base','exist(''ldCaseRoot'')')
%    cs = evalin('base','cs');
   ldCaseRoot = evalin('base','ldCaseRoot');
   resultFileName = [ldGetCaseFolderInfo(ldCaseRoot,'caseFolderName'),'_',resultFileName];
end


% store the whole base workspace
evalin('base',['save(''' resultFileName ''');']); 
[~, msgid] = lastwarn;
    
if strcmp(msgid,'MATLAB:save:sizeTooBigForMATFile')
    evalin('base',['save(''' resultFileName ''',''*'',''-v7.3'');']); % store the whole base workspace in v7.3 format
    warning('newLDYN:simTools:nlGenSimLogFile:SAVEv7_3', 'Result was saved with no (or less) compression (-v7.3 flag is set).');
end
pathResult = strrep(fileparts(pwd),'\tmp','\result');
if exist(pathResult,'dir') ~= 7
    mkdir(pathResult)
end
copyfile(resultFileName,fullfile(pathResult,resultFileName));

% Move CPC debug file to result folder
if exist('cpc_debug.csv', 'file')
    resultFileName_cpc = regexprep(resultFileName, '.mat', '_cpc.csv');
    movefile('cpc_debug.csv', fullfile(pathResult, resultFileName_cpc))
end


