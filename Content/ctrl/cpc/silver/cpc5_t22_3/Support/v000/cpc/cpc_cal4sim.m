% Change Calibration Data Set (CDS) parameter for simulation
% Can be different then in real vehicle, because ...
% - otherwise problems in simulation expected
% - higher flexibility in simulation possible

% cal parameter cannot be changed, because ...
% - CAL module not disabled for simulation --> original parameter from CDS file
% - automatic transmission
if ~exist('cal', 'var') || ~isfield(cal, 'cal_m_EnCal_u8') || cal.cal_m_EnCal_u8~=0
    return
end

% No automatic neutral after some time
cal.cal_g_AgAutoNeuReqActv_u1 = 0;

% Driving program can be deactivated by: 
% 0 = only driver
% 1 = time dependent
% 2 = torque dependent after minimum activation time
cal.cal_g_AgSftPrgDep_u2 = 0;

% Define mass for starting gear [kg]
% - needed for acceleration simulation, if VehWeight_Stat_PT = low at the beginning 
% - resolution of 4 kg is considered
cal.cal_g_AgDefaultMassStartGear_u16 = round(dep.veh_m_kg / 4) * 4; 