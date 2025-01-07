function fevalAllVersion(sFunction,sArg,sPathAdd)
% FEVALALLVERSION evaluate function in all installed MATLAB versions.
%
% Limitiations: R2013a code generation fails, when based on R2013b slx
% models. R2010a 64bit and R2010b 64bit require manual compiler selection
% accoring description below.
% 
% CAUTION: MATLAB R2010b (and SP1) requires an external compiler for 64bit
% and shares the compiler information among 32bit and 64bit version. To
% create a s-function for 64bit, open R2010b 64bit, set compiler via "mex
% -setup" and execute buildDIVeSfcn by hand. Open MATLAB R2010b 32bit and
% reset the compiler with "mex -setup" again.
% 
% Syntax:
%   fevalAllVersion(sFunction,sArg)
%
% Inputs:
%   sFunction - string with function name
%        sArg - string with function argument
%    sPathAdd - string with paths to add
%
% Outputs:
%
% Example: 
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\phys\eng\simple\transient\Module\std\std.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MCM21_m04_54\Module\std\std.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\ctrl\mcm\rebuild\MR2_r24\Module\std\std.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\ctrl\icuc\rebuild\silcpcConnect_v01\Module\prototype\prototype.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\air\std\Module\airConst\airConst.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\air\std\Module\airCalc\airCalc.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\air\std\Module\pressureCalc\pressureCalc.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\roadair\linc\Module\airConst\airConst.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\roadair\linc\Module\pressureCalc\pressureCalc.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
%   fevalAllVersion('buildDIVeSfcn','C:\dirsync\06DIVe\01Content\bdry\env\roadair\linc\Module\airCalc\airCalc.xml','C:\dirsync\06DIVe\00Common\03Code\DIVeMatlab')
% 
% See also: strsplitOwn
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-10-28

% determine installed MATLAB versions
sPath = getenv('PATH');
cPath = strsplitOwn(sPath,';');
% CAUTION there are several MATLAB folders on the system path - only start
% folders needed
cMatlab = regexpi(cPath,'(?<=matlab\\)[^\\]+(?=\\bin$)','match','once'); 
cPath = cPath(~cellfun(@isempty,cMatlab));
cMatlab = regexpi(cPath,'(?<=matlab\\)[^\\]+(?=\\bin$)','match','once'); 

% ask user for versions to process
nSelection = listdlg('ListString',cMatlab,...
            'Name','Select MATLAB versions to process');
cPath = cPath(nSelection);
cMatlab = cMatlab(nSelection);
        
% execute function in MATLAB versions
for nIdxVersion = 1:numel(cPath)
    sPathExe = fullfile(cPath{nIdxVersion},'matlab.exe');
    if exist(sPathExe,'file')
        [status,result] = system(['"' sPathExe '" -r addpath(genpath(''' sPathAdd '''));' ...
            'funcall(''' sFunction ''',''' sArg ''') -logfile log' cMatlab{nIdxVersion} '.txt']);
        pause(60)
    end
end
return
