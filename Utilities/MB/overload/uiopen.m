function uiopen(varargin)
% UIOPEN overloaded function of the standard MATLAB uiopen to open XML
% files as DIVe configuration with a DIVe ModelBased call to build the
% simulation model.
% If passed file is not a XML file, the original function is called
%
% Syntax:
%   uiopen(sFilePath)
%   uiopen(sFilePath,bDirect)
%
% Inputs:
%   sFilePath - string with filepath to be opened
%     nDirect - integer (original: boolean) with direct open/run argument
%               for DMB (==2 envokes build and start the simulation after
%               buildup), other see MATLAB builtin "uiopen"
%
% Example: 
%   uiopen(varargin)
%
% See also: dmb, uiopen (MATLAB)
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2016-03-15

% input check
if nargin > 0
    sFilePath = varargin{1};
else
    error('uiopen:noFileSpecfied','A file argument must be specified with uiopen!');
end
if nargin > 1
    bRun = varargin{2} == 2;
else
    bRun = 0;
end

% check file existence
if ~exist(sFilePath,'file')
    error('uiopen:FileNotFound','The specified file is not on the filesystem: %s',sFilePath);
end 

% determine orignal MATLAB function
cFilePath = which('uiopen','-all');
sPathNow = pwd;
cd(fileparts(cFilePath{end}));
hFunction = @uiopen;
cd(sPathNow);

% special handling for XMLs when DIVe ModelBased is available
[sPath,sFile,sExt] = fileparts(sFilePath); %#ok<ASGLU>
if strcmpi(sExt,'.xml') && exist('dmb','file')
    try
        % build DIVe MB model from configuration
        dmb(sFilePath,bRun);
    catch %#ok<CTCH>
        feval(hFunction,varargin{:});
    end
else
    feval(hFunction,varargin{:});
end
return
