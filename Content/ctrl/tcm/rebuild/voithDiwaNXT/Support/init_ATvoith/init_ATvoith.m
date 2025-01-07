function [] = init_ATvoith(varargin)

%% read input arguments:
if mod(nargin,2)==0
    for k=1:nargin/2
        if strcmp( varargin{2*k-1},'cPathDataVariant' )
            cPathDataVariant = varargin{2*k};
        elseif strcmp( varargin{2*k-1},'sPathRunDir' )
            sPathRunDir = varargin{2*k};
        elseif false
        end
    end
else
    error('number of arguments not even --> use argument/value pairs')
end

[pathstr_supportSet,name,ext] = fileparts(which(mfilename));

pathSplit = regexp(cPathDataVariant','\','split');
classTypes = cellfun(@(x) x{find(strcmp(x,'Data'))+1}, pathSplit, 'UniformOutput', false);

%% Identify Dataset for Voith DataClass "tx_ATvoith" --> then extract Path to chosen DataSet
idxMain = find(strcmp('tx_ATvoith',classTypes)==1);
pathstr = cPathDataVariant{idxMain};

%% Get sMP structure from base workspace
sMP = evalin('base','sMP');

%% Load selected Voith data from mat-files to sMP-structure
run(fullfile(pathstr,'prep_Values_NXT.m'))
sMP.ctrl.tcm.DIWA_BB_ParNames = DIWA_BB_ParNames_NXT;
clear DIWA_BB_ParNames_NXT
sMP.ctrl.tcm.DIWA_BB_ParValues = DIWA_BB_ParValues_NXT;
clear DIWA_BB_ParValues_NXT

%% Copy Voith_Data folder to Run directory
copyfile(fullfile(pathstr,'Voith_Data_NXT'),fullfile(sPathRunDir,'Voith_Data_NXT'));
sMP.ctrl.tcm.sVoithData = sPathRunDir;


tmp_ret_char = dlmread(fullfile(pathstr,'Voith_Data_NXT\sim\tc\NXT_Retarder.txt'));
sMP.ctrl.tcm.x_ret_GW_rpm = tmp_ret_char(:,1);
sMP.ctrl.tcm.y_ret_M_max = tmp_ret_char(:,2);






%{
for k = 1:length(classTypes)
    switch classTypes{k}
        case 'axle'
            nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'axle.m'), sMP);
        case 'ret'
            nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'ret.m'), sMP);
        case 'veh'
              nlLoadParam('sMP.ctrl.tcm', fullfile(cPathDataVariant{k},'veh.m'), sMP);
        otherwise
            % do nothing
    end
end

% % overwrite data
% powertrain data
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'mVeh', sMP.ctrl.tcm.mVeh/1000);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'rDyn', sMP.ctrl.tcm.rDyn/1000);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'iA', sMP.ctrl.tcm.axleiDiff);
% mcm data
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'eng_idleSpeed', sMP.ctrl.tcm.eng_idleSpeed);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'eng_maxSpeed', sMP.ctrl.tcm.eng_maxSpeed);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'eng_maxTorque', max(sMP.ctrl.tcm.eng_maxTorque));
% Further values
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'rhoAir', sMP.ctrl.tcm.rhoAir);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'fRFzg', sMP.ctrl.tcm.fRFzg);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'etaAxle', sMP.ctrl.tcm.etaAxle);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'mVeh_empty', sMP.ctrl.tcm.mVehEmpty);
sMP.ctrl.tcm.DIWA_BB_ParValues = fcChangeDiwaParam(sMP.ctrl.tcm.DIWA_BB_ParValues, sMP.ctrl.tcm.DIWA_BB_ParNames, ...
    'mVeh_load', sMP.ctrl.tcm.mVehMaxLoad-sMP.ctrl.tcm.mVehEmpty);
%}


%% update sMP structure in base workspace
assignin('base','sMP',sMP);
