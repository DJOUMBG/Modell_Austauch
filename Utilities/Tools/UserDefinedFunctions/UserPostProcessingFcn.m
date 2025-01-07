function UserPostProcessingFcn(varargin)
% USERPOSTPROCESSINGFCN user defined post-processing function executing at
% the very end of post-processing. The Matlab path is still in simulation
% directory.
%
% Syntax:
%   UserPostProcessingFcn
%
% Inputs:
%
% Outputs:
%
% Example: 
%   UserPostProcessingFcn

% Put your post-processing code here
% e.g. copy results to your personal access netshare - see robocopy.m
% wrapper for rather stable copy operation
% disp('test user-defined post processing fcn')

%% PEMS evaluation example
% pnt_MainPemsnoxCalculation(pwd);

%% ATF file copy example
% sMvaShare = '\\s019at0003mva.destr.corpintra.net\atf_simu';
% if exist(sMvaShare,'dir') == 0
%     fprintf(2,['Warning: MVA Share is not available for this client or ' ...
%                'user - copy of ATF files is omitted!']);
% end
% cFileAtfZyk = dirPattern(pwd,'\.ATF_ZYK','file',true);
% cFileAtfFu = dirPattern(pwd,'\.ATF_FU','file',true);
% if ~isempty(cFileAtfFu)
%     disp('Copy ATF_FU files to MVA share Laderampe::')
%     disp(cFileAtfFu)
%     robocopy(pwd,sMvaShare,cFileAtfFu);
% elseif ~isempty(cFileAtfZyk)
%     disp('Copy ATF_ZYK files to MVA share Laderampe:')
%     disp(cFileAtfZyk)
%     robocopy(pwd,sMvaShare,cFileAtfZyk);
% else
%     disp('No ATF files to copy.')
% end
return