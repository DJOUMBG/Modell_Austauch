function cFullpathList = fleFullpathCreate(sRootFolderpath,cFolderList)
% FLEFULLPATHCREATE creates the full path for each element in list by 
% concatenate root directory path with the subdirectory paths in list.
%
% Syntax:
%   cFullpathList = fleFullpathCreate(sRootFolderpath,cFolderList)
%
% Inputs:
%   sRootFolderpath - string: path with root directory 
%       cFolderList - cell (mxn): list with subfolders or subfiles in root directory 
%
% Outputs:
%   cFullpathList - cell (mxn): list of concatenated paths 
%
% Example: 
%   cFullpathList = fleFullpathCreate(sRootFolderpath,cFolderList)
%
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-24

% create full paths
hFull = @(x) fullfile(sRootFolderpath,x);
cFullpathList = cellfun(hFull,cFolderList,'UniformOutput',false);

return