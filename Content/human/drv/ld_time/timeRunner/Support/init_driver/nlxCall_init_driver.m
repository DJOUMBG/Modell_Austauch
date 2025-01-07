function [] = nlxCall_init_driver(varargin)
%% read input arguments:
if mod(nargin,2)==0
    for k=1:nargin/2
        if strcmp( varargin{2*k-1},'cPathDataVariant' )
            cPathDataVariant = varargin{2*k};
        elseif false
        elseif false
        end
    end
else
    error('number of arguments not even --> use argument/value pairs')
end

%%% BAUSTELLE PFAD FÜR DIVE ANDERS SETZEN
[pathstr_supportSet,name,ext] = fileparts(which(mfilename));
cPathDataVariant = cPathDataVariant';
pathSplit = regexp(cPathDataVariant','\','split');
classTypes = cellfun(@(x) x{find(strcmp(x,'Data'))+1}, pathSplit, 'UniformOutput', false);
% idxMain = find(strcmp('main',classTypes)==1);
% pathstr = cPathDataVariant{find(strcmp('main',classTypes)==1)};

%% get sMP structure from base workspace
sMP = evalin('base','sMP');

% dmdModuleTest?
if all(size(fieldnames(sMP)) == [1 1]) && strcmp(fieldnames(sMP),'human')
    dmdModuleTest = 1;
else
    dmdModuleTest = 0;
end

% notwendig für DIVe ModuleTest, sonst fehlen die Streckendaten
if dmdModuleTest
    pathstr = cPathDataVariant{find(strcmp('main',classTypes)==1)};
    sMP.bdry.env = load(fullfile(pathstr,'CYC.mat'));
end
% calculate brake pedal curve
BrkPdlCrv = flipud(-100*[sMP.human.drv.vehPara.ebs_zSoll_dx_yAxis_nom' sMP.human.drv.vehPara.ebs_zSoll_dx_xAxis_nom']);
% [~,nIdxMono]=unique(BrkPdlCrv(:,1),'legacy');
% unique-legacy-replacement:
copyBrkPdlCrv = unique(sort(BrkPdlCrv(:,1)));
nIdxMono=NaN(size(copyBrkPdlCrv));
for i = 1:1:length(copyBrkPdlCrv)
   nIdxFind = []; %#ok<NASGU>
   nIdxFind = find(BrkPdlCrv(:,1)==copyBrkPdlCrv(i));
   nIdxMono(i,1) = nIdxFind(end);
end

sMP.human.drv.vehPara.BrkPdlCurve = BrkPdlCrv(nIdxMono,:);

% set parameters for accelerator pedal curve
sMP.human.drv.vehPara.AccPdlCurve = [sMP.human.drv.vehPara.AccPdl_yAxis_nom' sMP.human.drv.vehPara.AccPdl_xAxis_nom'];

% full load curve: shape dimension to row vector, if necessary
if ~isrow(sMP.human.drv.vehPara.tbf_trq_max_r0_2m)
    sMP.human.drv.vehPara.tbf_trq_max_r0_2m = sMP.human.drv.vehPara.tbf_trq_max_r0_2m(:,1)';
end

eng_vel_rpm = [0  %% engine speed in rpm
100
620
1140
1660
2180
2546
2655
2700
3220
3740
4260
4780
5300
5820
6340
6860
7380
7900
8250
8276
8420
8940
9460
9980
10500
11020
11500]';

eng_tq = [455 %Engine torque
455
454
453
452
451
450
432
424
356
306
269
240
216
197
181
167
155
145
139
138
133
118
106
95
86
78
0]';

% if any(sMP.ctrl.mcm.tbf_trq_max_r1_2m)>0
%    eng_tq=sMP.ctrl.mcm.tbf_trq_max_r1_2m';
%    eng_vel_rpm=sMP.ctrl.mcm.tbf_trq_max_r1_2m;
% else 
%    eng_tq=sMP.ctrl.mcm.tbf_trq_max_r0_2m';
%    eng_vel_rpm=sMP.ctrl.mcm.tbf_trq_max_r0_2m;
% end
   
veh_speed_accln =[0    
2.8420 
4.7964   
16.8648   
20.5394   
24.9104   
32.9559   
41.0015   
45.0243   
53.0699   
61.1155   
64.0243   
69.1611   
73.1839   
81.2294   
88.9656];

Veh_Speed_Breaking=veh_speed_accln;

ctrl_gain = 0.1; %controller gain
eng_nr = 2; % Number of  motors
tq_max_tot = eng_tq.* eng_nr; % Maximum torque of all motors -- same as Mmax_motor
ine_per_wheel = 11.9; % Inertia per wheel

vehMass=sMP.human.drv.mass_gcw_kg; %mass of the vehicle

nrWheel=sMP.human.drv.vehPara.mec_axle_config(1); % number of wheels
cW_A=sMP.human.drv.aeroCdA_m2; % cW*A[m2]
kM = vehMass + (ine_per_wheel * nrWheel) / (sMP.human.drv.rdyn/1000);
kW = cW_A * sMP.human.drv.aeroRhoAirDensity_kgpm3; 

 % bhoefla:
% Stop Simulation added to driver! Calculation of stopDelay:
try
    name_section = {sMP.cfg.Configuration.OptionalContent.Section.name};
    idx_section = find(ismember(name_section,'DIVeModelBased')==1);
    if isfield(sMP.cfg.Configuration.OptionalContent.Section(idx_section).Logging,'Decimation')
    LogDecimation  = sMP.cfg.Configuration.OptionalContent.Section(idx_section).Logging.Decimation;
    else
        LogDecimation  = 1;
    end
    if isstr(LogDecimation)
        LogDecimation = str2double(LogDecimation);
    end
    LogSampleTime  = sMP.cfg.Configuration.OptionalContent.Section(idx_section).Logging.sampleTime;
    if isstr(LogSampleTime)
        LogSampleTime = str2double(LogSampleTime);
    end
    SimSampleTime = sMP.cfg.Configuration.MasterSolver.maxCosimStepsize;
    if isstr(SimSampleTime)
        SimSampleTime = str2double(SimSampleTime);
    end

if LogSampleTime > 0
    sMP.human.drv.stopDelay = LogSampleTime/SimSampleTime * LogDecimation;
else
     sMP.human.drv.stopDelay = LogDecimation;
end
catch
sMP.human.drv.stopDelay = 2001;
end

%% update sMP structure in base workspace
assignin('base','sMP',sMP);
