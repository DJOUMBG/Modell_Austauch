function [nChange,sMsg] = p4change(sDescription,cFile,sType)
% p4change - creates a changelist with high attribute details
%
% Syntax:
%   [nChange,sMsg] = p4change(varargin)
%
% Inputs:
%   sDescription - char (1xn) with description of new changelist
%          cFile - cell with arbitrary number of string arguments to p4
%          sType - string with changelist type 'public' or 'restricted'
%
% Outputs:
%   nChange - integer (1x1) with number of new created pending changelist
%      sMsg - string with output message
%
% Example: 
% % move all files from default changelist to new changelist with description
%   [nChange,sMsg] = p4change('Example description') % moves all files from default changelist to new   
% % move specified _opened_files from default changelist to new changelist with description
%   [nChange,sMsg] = p4change('Example description',{'File1.txt','File2.txt'})
% 
% See also: strGlue
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-10-23

% check input
if nargin < 2
    cFile = {};
end
if nargin < 3
    sType = 'restricted';
end

[nStatus,sMsg] = p4form('change',...
                        'Type',{sType},...
                        'Description',{sDescription},...
                        'Files',cFile);

if nStatus
    % failure of p4 command
    nChange = [];
    fprintf(2,'p4change failure with message:\n%s\n',sMsg);
else
    % determine actual changelist number
    nChange = sscanf(sMsg,'Change %i');
    if isempty(nChange)
        nChange = str2double(regexp(sMsg,'(?<=Change )\d+','match','once'));
    end
    if isempty(nChange)
        error('p4change:changeNumberRetrievalFailed',...
            'The capturing of the changelist number in p4change failed!');
    end
end
return