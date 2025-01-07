function [sMsg] = attrib(varargin)
% ATTRIB set windows file attributes like read-only (or remove them).
%
% Syntax:
%   sMsg = attrib(varargin)
%
% Inputs:
%   varargin - 
%
% Outputs:
%   sMsg - string 
%
% Example: 
%   sMsg = attrib('C:\dirsync\00Tools\01Functions\*') % list attributes of all files
%   attrib -R C:\dirsync\00Tools\01Functions\07UnifiedMessageSystem\umsClose.m % change attribute 
%   sMsg = attrib('-R','C:\dirsync\00Tools\01Functions\07UnifiedMessageSystem\umsClose.m')
%   attrib -R C:\dirsync\00Tools\01Functions\07UnifiedMessageSystem\*
%
%
% See also: strGlue, icacls, fileattrib('myfile.m','+w')
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-03-23

% Syntax
%       ATTRIB [ + attribute | - attribute ] [pathname] [/S [/D]]
% 
% Key
%      +    : Turn an attribute ON
%      -    : Clear an attribute OFF
% 
%  pathname : Drive and/or filename e.g. C:\*.txt
%     /S    : Search the pathname including all subfolders.
%     /D    : Process folders as well
% 
%    attributes: 
%         R  Read-only (1)
%         A  Archive (32)
%         S  System (4)
%         H  Hidden (2)
% 
%    extended attributes:
%         E  Encrypted
%         C  Compressed (128:read-only)
%         I  Not content-indexed
%         L  Symbolic link/Junction (64:read-only)
%         N  Normal (0: cannot be used for file selection)
%         O  Offline
%         P  Sparse file
%         T  Temporary 
%         X  No scrub file attribute (Windows 8+)
%         V  Integrity attribute (Windows 8+)

% combine input arguments
sCall = strGlue([{'attrib'},varargin],' ');
% system call
[nStatus,sMsg] = system(sCall); %#ok<ASGLU>
return