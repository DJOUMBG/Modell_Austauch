function [nIdx,sSelection] = guiSingleSelectDialog(cList,sName,nSize)
% GUISINGLESELECTDIALOG shows a list dialog in which the user can choose 
% between different options with single selection.
%   The function expects a list of options, which are displayed 
%   alphabetically sorted in the list dialog.
%
% Syntax:
%   guiSingleSelectDialog(cList,sName)
%   guiSingleSelectDialog(cList,sName,nSize)
%   nIdx = guiSingleSelectDialog(__)
%   [nIdx,sSelection] = guiSingleSelectDialog(__)
%
% Inputs:
%   cList - cell list of strings:
%       options displayed in list dialog
%   sName - string:
%       name of dialog window
%   nSize - integer (1x2) [optional], default = [300 400]:
%       user defined size of dialog window
%
% Outputs:
%	nIdx - integer (1x1):
%       index of selected option in given and unsorted list (cList)
%   sSelection - string:
%       name of selected option in given list (cList)
%
% See also: listdlg
%
% Author: Elias Rohrer, TE/PTC, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2024-03-15


% input arguments
if nargin < 3
    nSize = [300 400];
else
    if numel(nSize) ~= 2
        error('Size of list dialog must be two double values.');
    end
end

% init output
nIdx = []; %#ok<NASGU>
sSelection = {};

% format input list
cList = reshape(cList,numel(cList),1);

% create index list
nIdxList = 1:1:numel(cList);

% sort list alphabetically
[~,nSortIdx] = sort(upper(cList));
cList = cList(nSortIdx);
nIdxList = nIdxList(nSortIdx);

% show dialog
nIdx = listdlg('ListString',cList,...
    'SelectionMode','single',...
    'ListSize',nSize,...
    'Name',sName,...
    'PromptString',sName);

% check user input
if isempty(nIdx)
    return;
end

% collect selection
nIdx = nIdxList(nIdx);
sSelection = cList{nIdx};

end