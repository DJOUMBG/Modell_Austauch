
%% edrive drive parameter%%

%%%%%%VehicleParameter%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
aGrv = 9.8067; %accln due to gravity value
mass_gcw_kg = 13938;%sMP.phys.mec.mec_massVehicle_kg global parameter will overrite mass_gcw_kg
rdyn = 465;%sMP.phys.mec.mec_rWheelDriven global parameter will overrite rdyn
coefReRollgVeh = 0.0064; %sMP.phys.mec.mec_fRollCoeffOverall global parameter will overrite coefReRollgVeh
aeroCdA_m2 = 4.2515; %sMP.phys.mec.aero.aeroCdA_m2 global parameter will overrite aeroRhoAirDensity_kgpm3

gearration = 22.66;%% vehicle gear ration
aeroRhoAirDensity_kgpm3 = 1.2020; %sMP.phys.mec.aero.aeroRhoAirDensity_kgpm3 global parameter will overrite aeroRhoAirDensity_kgpm3

vehPara.cpc_e_Nm_max = 10000; %max. engine torque, cpc_e_Nm_max global parameter will overrite it
vehPara.mec_axle_config = [4 2];% (1): number of all wheels (2): number of driven wheels , mec_axleConfig global parameter will overrite it
vehPara.axleiDiff = 1; % Axle ratio mec_iDiffAxle global parameter will overrite it


%******************************
%******************************
%from Data/main/dep_para.m
vehPara.ebs_zSoll_dx_yAxis_nom = [0 1]; % [0 0 0 0.0250 0.0250 0.0250 0.0500 0.0570 0.157 0.160 0.190 0.200 0.225 0.250 0.300 0.399 0.400 0.450 0.500 0.550 0.600 0.650 0.700 0.750 0.799 0.800 0.900 1 1 1 1];
vehPara.ebs_zSoll_dx_xAxis_nom = [0 1]; % [0 0.01639344300 0.08114754100 0.08196721300 0.1221311480 0.1229508200 0.1557377050 0.1639344260 0.2868852460 0.2950819670 0.3278688520 0.3448825880 0.3803278690 0.4098360660 0.4549180330 0.5368770490 0.5377049180 0.5713114750 0.5991803280 0.6221311480 0.6450819670 0.6631147540 0.6836065570 0.6991803280 0.7104262300 0.7106557380 0.7319672130 0.7491803280 0.8114754100 1 1.229508197];
vehPara.AccPdl_yAxis_nom = [0 100]; 
vehPara.AccPdl_xAxis_nom = [0 100];
vehPara.BrkPdlCurve = [1 1 ;2 1]; % overwritten by "\Support\init_driver\nlxCall_init_driver.m" (and not by dependency.xml)
vehPara.tbf_trq_max_r0_2m = [424 422	423	423	423	423	423	422	422	422	422	422	422	422	421	421	421	421	421	421	421	421	421	420	420	420	420	420	420	420	420	420	419	419	419	419	419	419	419	418	413	407	400	392	384	375	367	359	351	343	335	327	319	312	305	297	290	283	276	270	263	257	251	245	240	234	229	224	220	215	210	206	202	198	194	191	187	183	180	177	174	171	168	165	162	159	157	154	151	149	147	144	142	140	138	136	134	132	130	128	126	124	123	121	119	118	116	115	113	112	110	109	108	106	105	104	102	101	100	99	97];% []; %  = [0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;]; % toptorque, else normal full load curve
%******************************
%******************************

vehPara.tcm_iGrFwrd = [	14.930
	11.673
	9.024
	7.056
	5.628
	4.400
	3.393
	2.653
	2.051
	1.604
	1.279
    1.00
    1.00
    1.00
    1.00
    1.00]'; % Ratio of forward gears tcm_iGrFwrd global parameter will overrite it
%%%%%%%%%GainScheduling%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Gain scheduling Integral gain
Mmax_motor = [910
910
908
906
904
902
900
864
848
712
612
538
480
432
394
362
334
310
290
278
276
266
236
212
190
172
156
0]';

vehPara.Nm_EM=Mmax_motor; % Maximum E-Motor Torque Table Data hvs_emot_trqMaxRow will overrite it
vehPara.rpm_EM=linspace(1,2000,length(Mmax_motor));% E-Motor loss- Speed Breakpoint Data hvs_emot_nTab_1stD will overrite it

Ki=[0
6.46226E-05
0.00040066
0.000736697
0.001072735
0.001408772
0.001645291
0.001715729
0.001744809
0.002080847
0.002416884
0.002752922
0.003088959
0.003424996
0.003761034
0.004097071
0.004433108
0.004769146
0.005105183
0.005331362
0.005348164
0.005441221
0.005777258
0.006113295
0.006449333
0.00678537
0.007121408
0.007431596
]';
ind=round(linspace(1,length(Ki),16));
Ki=Ki(ind);
%Gain scheduling Proportional gain
Kp_Accln = 0.3*[0.868351648
0.868351648
6*0.870264317
10*0.87218543
10*0.874115044
10*0.876053215
6*0.878
0.914583333
0.931839623
1.109831461
1.291176471
1.468773234
1.64625
1.829166667
2.005583756
2.182872928
2.365868263
2.549032258
2.724827586
2.842446043
2.863043478
2.970676692
3.348305085
3.727358491
4.158947368
4.594186047
5.065384615
5.065384615]';
ind=round(linspace(1,length(Kp_Accln),16));
Kp_Accln=Kp_Accln(ind);

Kp_Breaking = [0.868351648
0.868351648
0.870264317
0.87218543
0.874115044
0.876053215
0.878
0.914583333
0.931839623
1.109831461
1.291176471
1.468773234
1.64625
1.829166667
2.005583756
2.182872928
2.365868263
2.549032258
2.724827586
2.842446043
2.863043478
2.970676692
3.348305085
3.727358491
4.158947368
4.594186047
5.065384615
5.065384615]';
ind=round(linspace(1,length(Kp_Breaking),16));
Kp_Breaking=Kp_Breaking(ind);

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

% Kp_Breaking=Kp_Accln;
Veh_Speed_Breaking=veh_speed_accln;
Kp_v=[0.25,0.25,0.2,0.15,0.1,0.1,0.1,0.1,0.1;0,10,20,30,40,50,60,70,80];
%%%%%%%%%%%%%%%%Tuning%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Kp_corr=0.4;
Corr_const=1;
Kp_acc_const=10;
Kp_brk_const=1;
Ki_acc_const=1.25;
Ki_brk_const=1;

Kp_tune_Accln=[1 1 1 1 1];
Grad_Accln=[-8 -4 0 4 8];
Kp_grad_Accln=[Kp_tune_Accln(1)*Kp_Accln; Kp_tune_Accln(2)*Kp_Accln; Kp_tune_Accln(3)*Kp_Accln; Kp_tune_Accln(4)*Kp_Accln;Kp_tune_Accln(5)*Kp_Accln ];%Kp_grad_Accln is a function of gradient & vehicle speed

Ki_tune_Accln=1;
Ki_Accln=Ki_tune_Accln*Ki;%Ki_Accln is not slope dependent
Grad_breaking=[-4 -3 -2 -1 0 1 2 3];
Kp_tune_breaking=[1 1 1 1 1 1 1 1];
Kp_grad_breaking=[Kp_tune_breaking(1)*Kp_Breaking;Kp_tune_breaking(2)*Kp_Breaking;Kp_tune_breaking(3)*Kp_Breaking;Kp_tune_breaking(4)*Kp_Breaking;Kp_tune_breaking(5)*Kp_Breaking;Kp_tune_breaking(6)*Kp_Breaking;Kp_tune_breaking(7)*Kp_Breaking;Kp_tune_breaking(8)*Kp_Breaking;];%Kp_grad_breaking is a function of gradient
Ki_tune_breaking=1;
Ki_breaking=Ki_tune_breaking*Ki;

Ki_Accln=Ki_Accln;
Ki_breaking=Ki_breaking;

%%%%%%%%%% Set4 Tuning [March-June 2020] %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To switch OFF all tuning make Kp_corr = 1; ma_corr = 1; make rest 3 parameters 0
ma_corr = 0.6;  
grad_corr_tuning = 0.4;
corr_tuning = 1; % Switched On/Off the tuning scheduling 'wrt velocity'
accTuningFlag = 1; % Overall tuning wrt acc (done specifically Chile cycle, but improved driver braking behavior for other cycles as well)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Kp_acc=[1,2.5,2.5,2.5,2.5,2.5,3,4.5,5.5,6,6;0,10,20,30,40,50,60,70,80,90,100];
Kp_brk(1,:)=[1,1.25,1.25,1.5,1.5,1.5,1.7,1.8,1.8,1.8,2]*0.1;
Kp_brk(2,:)=[0,10,20,30,40,50,60,70,80,90,100];
Ki=[0.01,0.015,0.02,0.0225,0.03,0.035,0.04,0.045,0.05;0,10,20,30,40,50,60,70,80];
Ki_gain=1;
refMass=16262; %mass of AeroQueen 