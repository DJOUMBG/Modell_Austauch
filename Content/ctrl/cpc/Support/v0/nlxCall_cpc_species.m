function [] = nlxCall_cpc_species(varargin)
% nlxCall_init_silcpc <call function for the initalization of the sil cpc module>
%
%
% Syntax:  [] = nlxCall_init_silcpc(varargin)
%
% Inputs:
%    varargin - [<Unit>] <Description>
%
% Outputs:
%     -
%
% Example: 
%          
%
% Subfunctions:
% Private functions:
% Other m-files required:
% MAT-files required:
%
% See also: <OTHER_FUNCTION_NAME1>, <OTHER_FUNCTION_NAME2> 
%
% Author: weiguo sun
% Date:   25-Sep-2018
%
% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev::                                                      $
%   $Author::                                                   $
%   $Date::                                                     $
%   $URL$

%% ------------- BEGIN CODE --------------

% get current path
[pathstr_supportSet,name,ext] = fileparts(which(mfilename));
% add the path for CPC folder
addpath([pathstr_supportSet '\CPC'])
