function [sMsg,nStatus] = p4(varargin)
% P4 system wrapper function for Perforce Helix (P4) commands).
%
% Syntax:
%   p4 {produces output for support mails to support@perforce.com}
%   sMsg = p4(varargin)
%   [sMsg,nStatus] = p4(varargin)
%
% Inputs:
%   varargin - cell with arbitrary number of string arguments to p4
%
% Outputs:
%   sMsg - string with output message
%   nStatus - integer (1x1) with shell error code (0: ended succesful, >0:
%             error code)
%
% Example: 
%   nChange = 60;
%   sMsg = p4(sprintf('change -o %i',nChange))
% 
% Failures:
%   p4 -u asdf change -o 7681 % not existent user
%   p4 -p asdf change -o 7681 % TCP connect failed
% 
% See also: strGlue, p4FieldExpand, p4change, p4group, hlxDescribeParse,
%   hlxChangesParse, p4switch, p4form
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-10-23

% check input
if nargin < 1
    varargin = {'-Ztag','info'};
    disp('p4 -Ztag info')
else
    if any(double(varargin{1})==37)
        % expand shortcut for sprintf call
        varargin = {sprintf(varargin{1},varargin{2:end})};
    end
end

% parse input for global modifiers in p4login call pass on
sArg = strGlue(varargin,' ');
cArg = strsplitOwn(sArg,' ');
cGlobal = {'-p','-u'};
[bHit,nHit] = ismember(cGlobal,cArg);
nHit = nHit(bHit);
nArgGlobal = sort([nHit,nHit+1]);

% combine input arguments
sCall = ['p4 ' sArg];

% retry on error
nLoop = 1;
nStatus = 1;
while nStatus ~= 0 && nLoop < 5
    % execute command
    [nStatus,sMsg] = system(sCall);
    
    if nStatus
        % cover exceptions (assume not possible: empty = no settings as nStatus = 0)
        [bStatus,sIdent,sCure] = p4Exception(sMsg,0);
    
        switch sIdent
            case 'NoLogin'
                if exist('p4login','file')
                    % issue login
                    p4login(strGlue(cArg(nArgGlobal),' '));
                    % retry
                    nLoop = nLoop + 1; % reduce retries to 3
                else % no login function - no retry, but report to user
                    nLoop = 5;
                end
                
            case 'TCPfail' % TCP timeout or connection failure
                fprintf(1,'TCP connection failure during p4.m call - waiting 5s for retry.\n');
                pause(5); % wait some time for machine to recover, 5 retries
            
            case 'TrustRequest'
                % retry 1 after auto trust attempt
                nLoop = nLoop + 2;
                
            otherwise
                nLoop = 5; % no retries
        end
    
        % increment loop
        nLoop = nLoop + 1;
    end % if system call failed
end % while loop
if nStatus % open failure
    if bStatus % known failure - report cure message
        fprintf(2,'%s\n',sCure);
    else
        % unknown failure of p4 command - inform user
        fprintf(2,'p4 failure from command:\n%s\n\n  ...with message:\n%s\n',sCall,sMsg);
    end
end

% add output to clipboard for "-Ztag info" to paste into support mail
if nargin < 1
    clipboard('copy',sMsg);
end
return