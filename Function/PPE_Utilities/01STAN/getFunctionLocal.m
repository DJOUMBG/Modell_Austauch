function xFunction = getFunctionLocal(sPathFile)
% GETFUNCTIONLOCAL determines the local/internal functions of an mfile and
% returns their handles in a structure with function names as field names.
% 
% The function must placed in the investigation function as further
% subfunction.
%
% Syntax:
%   xFunction = getFunctionLocal
%
% Inputs:
%   sPathFile - string with filepath of matlab file to be checked 
%
% Outputs:
%   xFunction - structure with fields of internal function names
%
% Example: 
%   xFunction = getFunctionLocal(which(mfilename))
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2015-09-24

if ~strcmp('.m', sPathFile(end-1:end))
    sPathFile = [sPathFile '.m'];
end

% read file
cSubFunctions = {}; % initialize list
if exist(sPathFile,'file') == 2 
    fid = fopen(sPathFile,'r');
    cLines = textscan(fid, '%[^\n]', 'CommentStyle', '%');
    fclose(fid);
    cLines = cLines{1};
else
    return
end

% reduce to function definition lines
cLines = cLines(strncmp('function', cLines, 8));
if ~isempty(cLines) && length(cLines) > 1
    cLines = cLines(2:end); % first name is function itself
    cSubFunctions{length(cLines),1} = ''; % initialize cSubFunctions 
    for k = 1:length(cLines)
        cSubFunctions{k} =  regexprep(cLines{k},{'function\s+','.+=\s*','\(.*\)\s*','%.*'},''); %#ok<AGROW> % replace all parts of line, to leave only function name
    end
end

% create function handles
for nIdxFunction = 1:numel(cSubFunctions)
    xFunction.(cSubFunctions{nIdxFunction}) = eval(['@' cSubFunctions{nIdxFunction}]);
end
return