function xmlResortDiff(sFile1,sFile2,sTool)
% XMLRESORTDIFF ensure same tag sort order of XML files (resorts second
% one) and open them in a file compare tool
%
% Syntax:
%   xmlResortDiff(sFile1,sFile2)
%   xmlResortDiff(sFile1,sFile2,sTool)
%
% Inputs:
%   sFile1 - string with XML filepath (sort order master)
%   sFile2 - string with XML filepath (will be resorted)
%    sTool - string with favorite file compare tool ('beyond'|'p4merge)
%
% Outputs:
%
% Example: 
%   xmlResortDiff('c:\temp\File1.xml','c:\temp\File2.xml')
%   xmlResortDiff('c:\temp\File1.xml','c:\temp\File2.xml','p4merge')
%   xmlResortDiff('C:\dirsync\06DIVe\03Platform\com\Content\ctrl\mcm\sil\M19_10_00_51_EU_HDEP\Module\std\std.xml','C:\dirsync\06DIVe\03Platform\com\Content\phys\mec\pointmass\generic\Module\std\std.xml','p4merge')
%
% Subfunctions: fileCompare, getRegistryKey
%
% See also: dsxRead, dsxWrite, structFieldOrder
%
% Author: Rainer Frey, TT/XCF, Daimler Truck AG
%  Phone: +49-711-8485-3325
% MailTo: rainer.r.frey@daimlertruck.com
%   Date: 2022-05-12

% check input
if nargin<3
    sTool = 'beyond';
end

% read XMLs
x1 = dsxRead(sFile1,0,0);
x2 = dsxRead(sFile2,0,0);

% resort
x2 = structFieldOrder(x1,x2);

% write resorted structure to XML file
attrib('-R',sFile2);
dsxWrite(sFile2,x2,0);

% open compare tool
fileCompare(sFile1,sFile2,sTool)
return

% =========================================================================

function fileCompare(sFile1,sFile2,sTool)
% FILECOMPARE start file compare tool on 2 files
%
% Syntax:
%   fileCompare(sFile1,sFile2,sTool)
%
% Inputs:
%   sFile1 - string with XML filepath (sort order master)
%   sFile2 - string with XML filepath (will be resorted)
%    sTool - string with favorite file compare tool ('beyond'|'p4merge)
%
% Outputs:
%
% Example: 
%   fileCompare('c:\temp\File1.xml','c:\temp\File2.xml','p4merge')

% get compare tool along availability
sExeBeyond = getRegistryKey('HKEY_LOCAL_MACHINE','SOFTWARE\WOW6432Node\Scooter Software\Beyond Compare','ExePath');
if ~isempty(sExeBeyond) && strcmp(sTool,'beyond') % Beyond Compare
    sCall = sprintf('"%s" "%s" "%s"',sExeBeyond,sFile1,sFile2);
else % Perforce Helix p4merge tool
    sCall = sprintf('p4merge "%s" "%s"',sFile1,sFile2);
end

% open tool
[nStatus,sMsg] = system(sCall);
if nStatus
    fprintf(2,'System call of file compare tool failed with message:\n%s\n',sMsg);
end
return

% =========================================================================

function sKey = getRegistryKey(rootkey,subkey,key)
% GETREGISTRYKEY get registry key and return empty string, if not
% retreived.
%
% Syntax:
%   sKey = getRegistryKey(rootkey,subkey,key)

try 
    sKey = winqueryreg(rootkey,subkey,key);
catch % failure in key retrieval
    sKey = '';
end
return

