function slcLoadEnsure(sPathMdl,bVerbose)
% SLCLOADENSURE ensure that a certain Simulink model is loaded. Cares
% automatically about shadowed Simulink models and overloading
% Part of Simulink custom package slc.
%
% Syntax:
%   slcLoadEnsure(sPathMdl,bVerbose)
%
% Inputs:
%   sPathMdl - string with mdl-name on MATLAB path or mdl-filename with
%              full path
%   bVerbose - boolean (1x1) verbosity flag: 
%               false: no display
%               true:  display message if no loading is possible
%
% Outputs:
%
% Example: 
%   slcLoadEnsure('mymodel')
%   slcLoadEnsure('mymodel',false)
% 
% See also: ismdl
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2010-12-04

if nargin < 2
    bVerbose = false;
end

% divide path
[sPath,sFilename,sExt] = fileparts(sPathMdl);

% check input elements
if ~isempty(sPath) && exist(sPath,'dir') ~= 7
    error('slcLoadEnsure:FilepathNotValid','The specified file path is not valid: %s',sPath);
end
if ~ismember(exist(sPathMdl,'file'),[2,4]) && ... 
        (~ismember(exist([sPathMdl '.mdl'],'file'),[2,4]) || ...
         ~ismember(exist([sPathMdl '.slx'],'file'),[2,4]) )
    error('slcLoadEnsure:FileNotValid','The specified file is not valid: %s',sPathMdl);
end
if exist(sPathMdl,'file')~=4 && ~ismember(sExt,{'.mdl','.slx'})
    error('slcLoadEnsure:FileNotMdl','The specified file is no Simulink model: %s',sPathMdl);
end
if isempty(sPath)
    sPath = pwd;
end
   
% check if specified model is already loaded
TFload = true;
if ismdl(sFilename) 
    if strcmpi(get_param(sFilename,'filename'),which(sPathMdl))
        TFload = false;
        if bVerbose
            disp(['slcLoadEnsure: ' sFilename ' is already loaded from path: ' sPath])
        end
    else
        close_system(sFilename,0);
    end
end
   
% load simulink model
if TFload
    load_system(sPathMdl);
end
return
