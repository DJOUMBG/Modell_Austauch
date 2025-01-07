function GlobCalc_mcm(varargin)
% GLOBCALC_MCM calculation of new local parameters of MCM for global
% parameter requests.
%
% Syntax:
%   globCalc_mcm

% get sMP structure from base workspace
if evalin('base','exist(''sMP'',''var'')')
    sMP = evalin('base','sMP');
else
    error('globCalc_mcm:sMPmissingInBaseWorkspace',...
        'The DIVe parameter structure "sMP" was not found in the base workspace - exiting %s',...
        mfilename('fullpath'));
end

% Assign mcm struct for better code readability
mcm = sMP.ctrl.mcm;

% determine engine brake performance type
mcm.globCalc_sys_can_eng_brk_performance = 0;
if mcm.sys_eng_brk_perf_by_e2p_1m > 0
    if mcm.E2P_SYS_ENGINE_BRAKE_VARIANT == 1
        mcm.globCalc_sys_can_eng_brk_performance = 1;
    end
else
    if mcm.sys_can_eng_brk_performance_1m == 1
        mcm.globCalc_sys_can_eng_brk_performance = 1;
    end
end

% use respective max brake torque line
switch mcm.globCalc_sys_can_eng_brk_performance
    case 0
        mcm.globCalc_cac_br_trq_ebs1_max_2m_cons = mcm.cac_br_trq_ebs1_max_std_2m;
        mcm.globCalc_cac_br_trq_ebs2_max_2m_cons = mcm.cac_br_trq_ebs2_max_std_2m;
        mcm.globCalc_cac_br_trq_ebs3_max_2m_cons = mcm.cac_br_trq_ebs3_max_std_2m;
    case 1
        mcm.globCalc_cac_br_trq_ebs1_max_2m_cons = mcm.cac_br_trq_ebs1_max_2m;
        mcm.globCalc_cac_br_trq_ebs2_max_2m_cons = mcm.cac_br_trq_ebs2_max_2m;
        mcm.globCalc_cac_br_trq_ebs3_max_2m_cons = mcm.cac_br_trq_ebs3_max_2m;
end

% evaluate engine derate speed, in case of data sets for M12 osg_eng_speed_max_r0_1m is used, for M4 osg_eng_speed_max_1m
if isfield(mcm,'osg_eng_speed_max_r0_1m')
    mcm.globCalc_osg_eng_speed_max_1m = mcm.osg_eng_speed_max_r0_1m;
else
    mcm.globCalc_osg_eng_speed_max_1m = mcm.osg_eng_speed_max_1m;
end

% % desired idle speed at 20°C (obsolete)
% % mcm.globCalc_lig_eng_speed_des_at20C = interp1(...
% %     mcm.lig_eng_speed_des_x_t_coolant,...
% %     mcm.lig_eng_speed_des_2m,20,'linear');
% desired idle speed at standard operation
mcm.globCalc_lig_eng_speed_des_std = mcm.lig_eng_speed_des_2m(end);

% % maximum engine speed for starting mode at standard operation
% % global parameter is not required. Initial engine speed is set to 800rpm > eom_eng_speed_start_max_2m(end)
% mcm.globCalc_eom_eng_speed_start_max_std = mcm.eom_eng_speed_start_max_2m(end);

% Remap full load torque curves
bRemapTrq = 0;
% Get remap index
if length(mcm.tbf_trq_max_r0_2m) == 32 && isfield(mcm, 'tbf_trq_max_r0_eng_speed_idx_cpc_1m')
    idx0 = mcm.tbf_trq_max_r0_eng_speed_idx_cpc_1m + 1;
    idx1 = mcm.tbf_trq_max_r1_eng_speed_idx_cpc_1m + 1;
    idx2 = mcm.tbf_trq_max_r2_eng_speed_idx_cpc_1m + 1;
    bRemapTrq = 1;
elseif length(mcm.tbf_trq_max_r0_2m) == 32 && isfield(mcm, 'tbf_trq_max_rx_eng_speed_idx_cpc_3m')
    % catch case, that there are 12 max torque curves for u224 and newer
    idx_cpc = reshape(mcm.tbf_trq_max_rx_eng_speed_idx_cpc_3m,12,16);
    idx0 = idx_cpc(1,:) + 1;
    idx1 = idx_cpc(2,:) + 1;
    idx2 = idx_cpc(3,:) + 1;
    bRemapTrq = 1;
elseif length(mcm.tbf_trq_max_r0_2m) == 32 && isfield(mcm, 'tbf_trq_max_r0_eng_speed_idx_cpc_2m')
    % for u231 there are again vectors but renamed to 2m
    idx0 = mcm.tbf_trq_max_r0_eng_speed_idx_cpc_2m + 1;
    idx1 = mcm.tbf_trq_max_r1_eng_speed_idx_cpc_2m + 1;
    idx2 = mcm.tbf_trq_max_r2_eng_speed_idx_cpc_2m + 1;
    bRemapTrq = 1;
end
% Remap full load torque curves
if bRemapTrq
    mcm.tbf_trq_max_r0_x_eng_speed = mcm.tbf_trq_max_r0_x_eng_speed(idx0);
    mcm.tbf_trq_max_r1_x_eng_speed = mcm.tbf_trq_max_r1_x_eng_speed(idx1);
    mcm.tbf_trq_max_r2_x_eng_speed = mcm.tbf_trq_max_r2_x_eng_speed(idx2);
    mcm.tbf_trq_max_r0_2m = mcm.tbf_trq_max_r0_2m(idx0);
    mcm.tbf_trq_max_r1_2m = mcm.tbf_trq_max_r1_2m(idx1);
    mcm.tbf_trq_max_r2_2m = mcm.tbf_trq_max_r2_2m(idx2);
end

% Check speed sample points
if length(unique(mcm.tbf_trq_max_r0_x_eng_speed)) ~= length(mcm.tbf_trq_max_r0_x_eng_speed)
    error('%s: Check speed sample points of tbf_trq_max_r0_x_eng_speed for double entries', mfilename)
end

% catch case, that there are 12 max torque curves for u224 and newer
if ~isfield(mcm,'sys_can_speed_power_rating_1m')
    % u224: sys_can_speed_power_rating_rx_2m
    if isfield(mcm,'sys_can_speed_power_rating_rx_2m')
        mcm.sys_can_speed_power_rating_1m = mcm.sys_can_speed_power_rating_rx_2m(1);
        % u231 (and newer) sys_can_speed_power_rating_r0_1m
    elseif isfield(mcm,'sys_can_speed_power_rating_r0_1m')
        mcm.sys_can_speed_power_rating_1m = mcm.sys_can_speed_power_rating_r0_1m;
    end
end

% catch case, that there are 12 max torque curves for u224 and newer
if ~isfield(mcm,'sys_can_performance_class_1m')
    % u224: use sys_can_performance_class_rx_2m
    if isfield(mcm,'sys_can_performance_class_rx_2m')
        % mcm.sys_can_performance_class_1m = mcm.sys_can_performance_class_rx_2m(1);
        mcm.sys_can_performance_class_1m = round(max(mcm.tbf_trq_max_r0_x_eng_speed.*mcm.tbf_trq_max_r0_2m*2*pi/60/1e3));
        if mcm.sys_can_performance_class_1m ~= mcm.sys_can_performance_class_rx_2m(1)
            warning('sys_can_performance_class_rx_2m(1) = %gkW has not the correct rating. Using %gkW', ...
                mcm.sys_can_performance_class_rx_2m(1), mcm.sys_can_performance_class_1m);
        end
        % u231 (and newer) sys_can_performance_class_r0_1m
    elseif isfield(mcm,'sys_can_performance_class_r0_1m')
        mcm.sys_can_performance_class_1m = mcm.sys_can_performance_class_r0_1m;
    end
end

% with u231 the array size of tfc_fm_tmh_3m is 16x24 and vector size of tfc_fm_tm_y_trq is 24.
% for now only the first 16 columns are transferred to cpc.
mcm.tfc_fm_tmh_3m   = mcm.tfc_fm_tmh_3m(:,1:16);
mcm.tfc_fm_tm_y_trq = mcm.tfc_fm_tm_y_trq(1:16);

% transfer sMP structure back to Module workspace
sMP.ctrl.mcm = mcm;
assignin('base','sMP',sMP);
return