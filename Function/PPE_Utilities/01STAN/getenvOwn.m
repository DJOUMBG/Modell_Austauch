function varargout = getenvOwn(cArg,cValue)
% GETENVOWN wrapper of Matlab's getenv function for syntax conform use
% under windows and linux systems. Also provides basic compare
% functionality for code shortcuts: strcmpi between environment values and
% defaults values. 
%
% Syntax:
%   varargout = getenvOwn(cArg,cValue)
%
% Inputs:
%     cArg - cell (1xn) with strings of environment settings to request,
%            use windows arguments, they get converted to linux settings,
%            if needed
%   cValue - cell (1xn) with strings of default values
%
% Outputs:
%   varargout - output value(s) 
%                   cell (1xn) with one argument
%                   boolean (1x1) with two arguments (string compare
%                   result)
%
% Example: 
%   sUser = getenvOwn('username')
%   [sUser,sHost] = getenvOwn({'username','computername'})
%   bUser = getenvOwn('username','rafrey5')
%   bAll = getenvOwn({'username','computername'},{'rafrey5','C019L061023'})
%
% Author: Rainer Frey, TP/EAC, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-06-02

% input check
if ischar(cArg)
    cArg = {cArg};
end
cArg = lower(cArg);

% adapt requested arguments to linux environment
sArchitecture = computer('arch');
if strncmp(sArchitecture,'glnx',4)
    cArg = regexprep(cArg,{'^username$','^computername$','^userdomain$','^home$'},...
                          {'USER','HOST','LINUX','HOME'},'ignorecase','once');
end

% get environemnt variables
cOut = cArg;
for nIdxArg = 1:numel(cArg)
    if strcmp(cArg{nIdxArg},'LINUX') % patch non-linux env settings
        cOut{nIdxArg} = 'LINUX';
    else % query system
        cOut{nIdxArg} = getenv(cArg{nIdxArg});
    end
end

% correction of Win11 EntraID username settings (last/firstname(org))
[bUser,nUser] = ismember('username',cArg);
if bUser && (~isempty(strfind(cOut{nUser},'(')) || ...
        (numel(cOut{nUser})>9 && ~strcmpi(cOut{nUser},'e019_tpc-pc_s_diveq')))
    [nStatus,sMsg] = system('whoami /upn'); %#ok<ASGLU>
    sUser = regexp(sMsg,'^\w+','match','once');
    cOut{nUser} = sUser;
end

% comparison shortcut
if nargin == 2
    % check input
    if ischar(cValue)
        cValue = {cValue};
    end
    
    % check arguments with compare values
    if numel(cArg) ~= numel(cArg)
        error('getenvOwn:compValueNumel',...
            'Number of compare values does not match number of requested environemnt elements!');
    end
    
    % compare to default values
    varargout = {true};
    for nIdxArg = 1:numel(cArg)
        varargout = {strcmpi(cOut{nIdxArg},cValue{nIdxArg})};
        if ~varargout{1} % break in case of mismatch
            return
        end
    end
else
    % standard output of environment settings
    varargout = cOut;
end
return