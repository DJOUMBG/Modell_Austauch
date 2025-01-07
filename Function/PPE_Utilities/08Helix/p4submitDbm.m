function p4submitDbm(nChange)
% P4SUBMITDBM comfort submit function for DIVe function and Simulink
% Simulation Technology with file specific pcopy and p4 copy to d_main.
%  - determine files of change(s) and descriptions
%  - init pcopy of files in Matlab R2010b, include adding to changelist
%  - submit to dbm/dam stream
%  - p4copy up to d_main
%
% Syntax:
%   p4submitDbm(nChange)
%
% Inputs:
%   nChange - integer (1xn)  with changelist numbers to derive the
%             changelist description for copy
%
% Outputs:
%
% Example: 
%   p4submitDbm(nChange)

% check input
if nargin < 1
    sMsg = p4('changes -m 10 --me');
    cMsg = strsplitOwn(sMsg,char(10)); %#ok<CHARTEN>
    [nSelection] = listdlg('ListString',cMsg,...
                    'PromptString','Select changelists for description transfer.',...
                    'Name','Select changelists',...
                    'ListSize',[600 300]);
     if isempty(nSelection)
         return
     else
         cOut = hlxOutParse(sMsg,' ',2,true);
         cSelection = cOut(nSelection,2);
         cSelNum = cellfun(@str2double,cSelection,'UniformOutput',false);
         nChange = cell2mat(cSelNum);
     end
end

% get change description
if isnumeric(nChange)
    xChange = hlxDescribeParse(nChange);
    sDescription = strGlue({xChange.sDescription},', ');
    cFile = {};
    for nIdxChange = 1:numel(xChange)
        cFile = [cFile;xChange(nIdxChange).cFile];
    end
else
    error('p4propagate:unknownArgument','Unknown Argument - needs to be an integer.')
end

% check int files for com counterpart

% targetted pcopy

% switch to dbm_platform
p4switch('C:\dirsync\06DIVe\03Platform\com',0);
p4('sync');
% transfer Utilities to com folder tree
run('C:\dirsync\06DIVe\03Platform\pcopy2comPPEUtility.m');
run('C:\dirsync\06DIVe\03Platform\pcopy2comDBC.m');
p4switch('//DIVe/d_main',0);

% copy up from dam_platform to d_main
p4copy('//DIVe/dam_platform',sDescription,cPathPart);

return
