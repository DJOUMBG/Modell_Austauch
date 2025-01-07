function [e, xCPC] = read_cpc_engine(xCPC)
% READ_CPC_ENGINE read cpc parameterized engine from CPC3_EEP
% and plots fuel map and other engine information of CPC3_EEP
%
% Syntax:  [e] = read_cpc_engine(xCPC)
%
% Inputs:
%    xCPC - [.] CPC3_EEP structure
%    xCPC - [''] path to CPC par file
%
% Outputs:
%    e - [.] Datastructure of diesel engine
%             e.kgh_map  - [kg/h] fuel map (m x n)
%             e.rpm_map  - [rpm] data points for fuel map (1 x n)
%             e.Nm_map   - [Nm] data points for fuel map (m x 1)
%             e.rpm_full - [rpm] full load curve
%             e.Nm_full  - [Nm] full load curve
%             e.rpm_fric - [rpm] drag / friction curve
%             e.Nm_fric  - [Nm] drag / friction curve (negative values)
%             e.rpm_exh  - [rpm] engine / exhaust brake
%             e.Nm_exh   - [Nm] engine / exhaust brake (negative values)
%             e.rpm_trans_step - [rpm] Uncharged full load curve
%             e.Nm_trans_step  - [Nm] Uncharged full load curve
%
% Example: 
%    read_cpc_engine(); % take CPC3_EEP from base workspace
%    read_cpc_engine(CPC3_EEP);
%    read_cpc_engine(sMP.ctrl.cpc.EEP);
%    read_cpc_engine('C:\SIL_Environment\CPC\EEP\963V119_003371.par');
%
%
% See also: plotEngine, read_cpc3_par_file
%
% Author: ploch37
% Date:   09-May-2014

%% check input
% use CPC3_EEP from base workspace
if nargin == 0
    try
        xCPC = evalin('base', 'CPC3_EEP');
    catch
        xCPC = evalin('base', 'sMP.ctrl.cpc.EEP');
    end
end
% read par file first
if ischar(xCPC)
    xCPC = read_cpc3_par_file(xCPC);
end
% check between old and new definitions
if isfield(xCPC, 'ptconf_p_Eng')
    sEng        = 'ptconf_p_Eng';
    sEngConsum  = 'ptconf_p_EngConsum';
    sEngFric    = 'ptconf_p_EngFric';
    sEngBrk     = 'ptconf_p_EngBrk';
elseif isfield(xCPC, 'ptconf_a_Eng')
    sEng        = 'ptconf_a_Eng';
    sEngConsum  = 'ptconf_a_EngConsum';
    sEngFric    = 'ptconf_a_EngFric';
    sEngBrk     = 'ptconf_a_EngBrk';
end

%% name
e.sName = sprintf('EngType_u8 = %d, EURO %d, %.4f kgm²', ...
    xCPC.(sEng).EngType_u8, ...
    xCPC.(sEng).CombustionClass_u8, ...
    xCPC.(sEng).EngInertiaTrq_u16/4096);


%% fullload
e.sFull         = 'TrbChFullLoadEngTrqCurve_u16 / TopTrqRedFullLoadEngTrqCurve_u16';
e.rpm_full      = (xCPC.(sEng).FullLoadEngTrqCurvesEngSpds_u16) * 0.16;
e.Nm_full       = (xCPC.(sEng).TrbChFullLoadEngTrqCurve_u16 - 25000) * 0.2;
e.rpm_full(2,:) = (xCPC.(sEng).TopTrqRedEngTrqCurveEngSpds_u16) * 0.16;
e.Nm_full(2,:)  = (xCPC.(sEng).TopTrqRedFullLoadEngTrqCurve_u16 - 25000) * 0.2;
e.sTransient    = 'UnChFullLoadEngTrqCurve_u16';
e.rpm_trans_step = e.rpm_full(1,:);
e.Nm_trans_step = (xCPC.(sEng).UnChFullLoadEngTrqCurve_u16 - 25000) * 0.2;


%% fuel map
e.sMap      = 'EngConsumMapFuelMass_u16';
e.rpm_map   = xCPC.(sEngConsum).EngConsumMapEngSpds_u8 * 16;
e.Nm_map    = xCPC.(sEngConsum).EngConsumMapEngTrqs_u8' * 20;
kW          = e.Nm_map * e.rpm_map * pi/30 / 1000;

gkWh        = xCPC.(sEngConsum).EngConsumMapFuelMass_u16 / 32;
e.kgh_map   = gkWh .* kW / 1000;


%% friction
e.rpm_fric  = (xCPC.(sEngFric).EngFricTrqMapEngSpd_u8)* 16;
degC = xCPC.(sEngFric).EngFricTrqMapTemp_u8 - 100;
idx_fric = find(degC >= 80, 1, 'first');
if isempty(idx_fric)
    idx_fric = 1;
end
e.Nm_fric   = (xCPC.(sEngFric).EngFricTrqMapTrq_u16(idx_fric,:) - 25000) * 0.2;
e.sFric     = sprintf('EngFricTrqMapTrq_u16 @ %.0f°C', degC(idx_fric));

%% plot
plotEngine(e, [], 0, 1);
rpm_max0 = xCPC.(sEng).MaxEngSpdGov0EngSpd_u16 * 0.16;
rpm_maxBrake = xCPC.(sEng).MaxPermEngBrkSpd_u16 * 0.16;
Nm_max = ceil((max(e.Nm_full(e.Nm_full~=8107))+50)/100)*100; % +50Nm buffer for display, 8107 Nm = SNA
xlim([min(e.rpm_map), min(rpm_max0, max(e.rpm_map(e.rpm_map~=4080)))]) % 4080 rpm = SNA
ylim([min(e.Nm_fric), min(Nm_max, max(e.Nm_map(e.Nm_map~=5100)))]) % 5100 Nm = SNA
% Maximum permitted engine speed during engine brake mode before mechanical destruction of engine
hold on
plot(rpm_max0, 0, 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'k', 'Displayname', 'MaxEngSpdGov0EngSpd_u16')
plot(rpm_maxBrake, -100, 'b', 'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'b', 'Displayname', 'MaxPermEngBrkSpd_u16')
hold off

%% plot brake torque curves
hold on
plot(xCPC.(sEngBrk).EngBrkStp1TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp1MaxBrkTrqs_u16-25000)*0.2, 'k--', 'Displayname', 'exhaust brake torque level1 min')
plot(xCPC.(sEngBrk).EngBrkStp1TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp1MinBrkTrqs_u16-25000)*0.2, 'k--', 'Displayname', 'exhaust brake torque level1 max')
plot(xCPC.(sEngBrk).EngBrkStp2TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp2MaxBrkTrqs_u16-25000)*0.2, 'k-', 'Displayname', 'exhaust brake torque level2 min')
plot(xCPC.(sEngBrk).EngBrkStp2TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp2MinBrkTrqs_u16-25000)*0.2, 'k-', 'Displayname', 'exhaust brake torque level2 max')
plot(xCPC.(sEngBrk).EngBrkStp3TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp3MaxBrkTrqs_u16-25000)*0.2, 'k:', 'Displayname', 'exhaust brake torque level3 min')
plot(xCPC.(sEngBrk).EngBrkStp3TrqCrvEngSpds_u8*16,(xCPC.(sEngBrk).EngBrkStp3MinBrkTrqs_u16-25000)*0.2, 'k:', 'Displayname', 'exhaust brake torque level3 max')
hold off
