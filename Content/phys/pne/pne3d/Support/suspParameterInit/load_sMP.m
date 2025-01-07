function load_sMP(varargin)

% debugger stop
% dbstop at 40

% input argument parsing
xArg = parseArgs({'sPathRunDir','','';...
                  'sPathModelLib','','';...
                  'sModelBlockPath','','';
                  'cPathDataVariant',{},''}...
                  ,varargin{:});
% cPathModelLib = pathparts(xArg.sPathModelLib);

% get structure variable to base workspace
sMP = evalin('base','sMP');

% function zReferenceTrailer
function [zReferenceTrailer,var_out,trlr_ctrl] = zReferenceTrailer(controlType,trailerType,zReference)
    var_out = '';
    % "no trailer brake"
    if round(controlType(1))==0
        var_out = strcat(var_out,'no trailer brake\n');
        zReferenceTrailer = 0;    % bei 4.5bar
        trlr_ctrl = [0,1.0,2.0,3.0,4.0,5.0,0.0,0.0,0.0,0.0,0.0];
    % "no trailer weight control"
    elseif round(controlType(1))==4
        var_out = strcat(var_out,'no trailer weight control\n');
        zReferenceTrailer = zReference;    % bei 4.5bar
        trlr_ctrl = [4,1.0,2.0,3.0,4.0,5.0,1.0,2.0,3.0,4.0,5.0];
    % "trailer control by given characteristics"
    elseif round(controlType(1))==5
        var_out = strcat(var_out,'trailer control by given characteristics\n');
        zReferenceTrailer = interp1(controlType(2:6),controlType(7:11),4.5);    % bei 4.5bar
        trlr_ctrl = controlType;
	end
    % semitrailer reference point 4.5bar
    if round(trailerType)==0
        % "Band unten"
        if round(controlType(1))==1
            var_out = strcat(var_out,'Band unten\n');
            zReferenceTrailer = 29;    % bei 4.5bar
            % trlr_ctrl = [1,0.1,0.15,1.0,4.5,7.5,0.0,0.0,0.0,0.29,0.45];
			trlr_ctrl = [1,0.2,0.5,1.3,4.5,10,0,0.03,0.03,0.29,0.583333333333333];
        % "Band mitte"
        elseif round(controlType(1))==2
            var_out = strcat(var_out,'Band mitte\n');
            zReferenceTrailer = 35;    % bei 4.5bar
            % trlr_ctrl = [2,0.1,0.15,0.6,4.5,7.5,0.0,0.0,0.0,0.35,0.55];
            trlr_ctrl = [2,0.2,0.5,0.9,4.5,10,0,0.03,0.03,0.35,0.716666666666667];
        % "Band oben"
        elseif round(controlType(1))==3
            var_out = strcat(var_out,'Band oben\n');
            zReferenceTrailer = 41;    % bei 4.5bar
            trlr_ctrl = [3,0.1,0.15,0.2,4.5,7.5,0.0,0.0,0.0,0.41,0.65];
	    end
    % trailer reference point 4.5bar
    else
        % "Band unten"
        if round(controlType(1))==1
            var_out = strcat(var_out,'Band unten\n');
            zReferenceTrailer = 35;    % bei 4.5bar
            % trlr_ctrl = [1,0.1,0.15,1.0,4.5,7.5,0.0,0.0,0.0,0.35,0.575];
            trlr_ctrl = [1,0.2,0.5,1.3,4.5,10,0,0.03,0.03,0.35,0.7625];
        % "Band mitte"
        elseif round(controlType(1))==2
            var_out = strcat(var_out,'Band mitte\n');
            zReferenceTrailer = 41.1;    % bei 4.5bar
            % trlr_ctrl = [2,0.1,0.15,0.6,4.5,7.5,0.0,0.0,0.0,0.411,0.6875];
            trlr_ctrl = [2,0.2,0.5,0.9,4.5,10,0,0.03,0.03,0.411,0.917916666666667];
         % "Band oben"
        elseif round(controlType(1))==3
            var_out = strcat(var_out,'Band oben\n');
            zReferenceTrailer = 47.1;    % bei 4.5bar
            trlr_ctrl = [3,0.1,0.15,0.17,0.2,7.5,0.0,0.0,0.0,0.0,0.8];
        % "no trailer weight control"
        end
    end
end


% spring type at axle 0-->undefined, 1-->air, 2-->steel
AxleSpringType=[0 0 0 0];
axle = 1;

% var = '---------\n';

var_tractor = '';

var_trlr = '---------\n';
var_trlr = strcat(var_trlr,'Trailer\n');

var_trlr02 = 'Trailer02\n';


% loop over all data sets
for k = 1 : length(xArg.cPathDataVariant)
  % fprintf('xArg.cPathDataVariant{%d} = %s\n', k, xArg.cPathDataVariant{k});
  % fprintf('%s\n',fileparts(xArg.cPathDataVariant{k}));
  % search for "susp" data set
  % find variant of suspension data set
  if strfind( xArg.cPathDataVariant{k},'phys\pne\Data\susp\')
    % fprintf('xArg.cPathDataVariant{%d} = %s\n', k, xArg.cPathDataVariant{k});
	% find name of suspension data set
	SuspType = strrep(xArg.cPathDataVariant{k},fileparts(xArg.cPathDataVariant{k}),'');
	% air spring?
	if strfind(SuspType,'AxleAirSpring')
	    AxleSpringType(axle:axle) = 1;
	% steel spring?
	elseif strfind(SuspType,'AxleSteelSpring')
	    AxleSpringType(axle:axle) = 2;
	% else
	%     AxleSpringType(axle:axle) = -1;
	end
	% next axle
	axle = axle + 1;
    % fprintf('---------\n');
  end
  % find name of trailer control set
  if strfind( xArg.cPathDataVariant{k},'phys\pne\Data\circTrlr\')
	% find name of trailer control data set
	TrlrType = strrep(xArg.cPathDataVariant{k},fileparts(xArg.cPathDataVariant{k}),'');
	% semi trailer?
	if strfind(TrlrType,'semiTrlr')
        var_trlr = strcat(var_trlr,sprintf('semi trailer: %s',regexprep(TrlrType,'[^a-zA-Z0-9_]','')),'\n');
		flagTrailerType = 0;
	% other trailer?
	else
        var_trlr = strcat(var_trlr,sprintf('other trailer: %s',regexprep(TrlrType,'[^a-zA-Z0-9_]','')),'\n');
        flagTrailerType = 1;
	end
  end
  % find name of trailer02 control set
  if strfind( xArg.cPathDataVariant{k},'phys\pne\Data\circTrlrRT\')
	% find name of trailer control data set
	TrlrType = strrep(xArg.cPathDataVariant{k},fileparts(xArg.cPathDataVariant{k}),'');
	% semi trailer?
	if strfind(TrlrType,'semiTrlr')
        var_trlr02 = strcat(var_trlr02,sprintf('semi trailer: %s',regexprep(TrlrType,'[^a-zA-Z0-9_]','')),'\n');
		flagTrailer02Type = 0;
	% other trailer?
	else
        var_trlr02 = strcat(var_trlr02,sprintf('other trailer: %s',regexprep(TrlrType,'[^a-zA-Z0-9_]','')),'\n');
        flagTrailer02Type = 1;
	end
  end
end
% axle = 1 --> sMP.phys.pne.susp1

% Vehicle/tractor mass
massTractor=sum(sMP.phys.pne.veh.axleLoadTractor_kg);
% Trailer mass
massTrailer=sum(sMP.phys.pne.veh.axleLoadTrailer_kg);

% Trailer control
zRef = 45;   % 45% bei 4.5bar
control = sMP.phys.pne.circTrlr.flagTrailerControlActive;     % globaler Parameter wegen Reihenfolge pne_flagTrailerControlActive, aber Daten kommen aus pne
var_trlr = strcat(var_trlr,sprintf('flagTrailerControlActive: %7.7f',control(1)),'\n');
[zRefTrailer,var_out,trlr_ctrl] = zReferenceTrailer(control,flagTrailerType,zRef);
var_trlr = strcat(var_trlr, sprintf(var_out),'\n');

% z correction for the trsctor
zRefTractor = zRef * (1 + massTrailer / massTractor * (1-zRefTrailer/zRef));
var_tractor = strcat(var_tractor, sprintf('zRef / zRefTractor / zRefTrailer: %7.7f / %7.7f / %7.7f',zRef,zRefTractor,zRefTrailer),'\n');

% read rdyn
% rdynTractor = sMP.phys.pne.veh.rdynTractor;
rdynTrailer = sMP.phys.pne.veh.rdynTrailer;


if 1
  var_rdyn = '';
  var_rdyn = strcat(var_rdyn,'---------\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTractor 1: %7.1f',sMP.phys.pne.veh.rdynTractor(1)),'\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTractor 2: %7.1f',sMP.phys.pne.veh.rdynTractor(2)),'\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTractor 3: %7.1f',sMP.phys.pne.veh.rdynTractor(3)),'\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTractor 4: %7.1f',sMP.phys.pne.veh.rdynTractor(4)),'\n');
  var_rdyn = strcat(var_rdyn,'---------\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer 1: %7.1f',rdynTrailer(1)),'\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer 2: %7.1f',rdynTrailer(2)),'\n');
  var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer 3: %7.1f',rdynTrailer(3)),'\n');
end


var = '---------\n';
var = strcat(var,'Tractor\n');
var_trlr = strcat(var_trlr,'---------\n');
% var_trlr = strcat(var_trlr, sprintf('pApp Trailer mean: %7.7f',pAppTrailer_mean),'\n');
% var_trlr = strcat(var_trlr,'---------\n');

stepSize = sMP.phys.pne.settings_dt;
% var = strcat(var,sprintf('settings_dt 1: %7.5f',stepSize),'\n')
sMP.phys.pne.veh.stepSize = stepSize;


% roadtrain
massTrailer02=sum(sMP.phys.pne.veh.axleLoadTrailer02_kg);
if massTrailer02 > 10
    rdynTrailer02 = sMP.phys.pne.veh.rdynTrailer02;
    var_rdyn = strcat(var_rdyn,'---------\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 1: %7.1f',rdynTrailer02(1)),'\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 2: %7.1f',rdynTrailer02(2)),'\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 3: %7.1f',rdynTrailer02(3)),'\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 4: %7.1f',rdynTrailer02(4)),'\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 5: %7.1f',rdynTrailer02(5)),'\n');
    var_rdyn = strcat(var_rdyn, sprintf('rdynTrailer02 6: %7.1f',rdynTrailer02(6)),'\n');

    % Trailer control
    control = sMP.phys.pne.circTrlr02.flagTrailerControlActive;    % globaler Parameter wegen Reihenfolge pne_flagTrailerControlActive, aber Daten kommen aus pne
    var_trlr02 = strcat(var_trlr02,sprintf('flagTrailerControlActive: %7.7f',control(1)),'\n');
    [zRefTrailer02,var_out,trlr_ctrl_02] = zReferenceTrailer(control,flagTrailer02Type,zRef);
    var_trlr02 = strcat(var_trlr02, sprintf(var_out),'\n');

    % write back to sMP structure
    sMP.phys.pne.circTrlr02.flagTrailerControlActive = trlr_ctrl_02;
	sMP.phys.pne.veh.pAppCyl_Trailer02 = [sMP.phys.pne.cylTrailer02A1.pApp, sMP.phys.pne.cylTrailer02A2.pApp, sMP.phys.pne.cylTrailer02A3.pApp, sMP.phys.pne.cylTrailer02A4.pApp, sMP.phys.pne.cylTrailer02A5.pApp, sMP.phys.pne.cylTrailer02A6.pApp]/1e5;

else
    var_trlr02 = strcat(var_trlr02, sprintf('No road train'),'\n');
    var_trlr02 = strcat(var_trlr02,'---------\n');
end

% write back to sMP structure
sMP.phys.pne.veh.AxleSpringType=AxleSpringType;

sMP.phys.pne.circTrlr.flagTrailerControlActive = trlr_ctrl;    % globaler Parameter wegen Reihenfolge pne_flagTrailerControlActive, aber Daten kommen aus pne
% application pressures for ebs and pneAux
sMP.phys.pne.veh.pAppCyl_Tractor = [sMP.phys.pne.cyl1.pApp, sMP.phys.pne.cyl2.pApp, sMP.phys.pne.cyl3.pApp, sMP.phys.pne.cyl4.pApp] /1e5;
sMP.phys.pne.veh.pAppCyl_Trailer = [sMP.phys.pne.cylTrailer1.pApp, sMP.phys.pne.cylTrailer2.pApp, sMP.phys.pne.cylTrailer3.pApp]/1e5;


% Thermal calculation 0->No/1->Yes
if sMP.phys.pne.initialTemperatures.TemperatureCalculation < 0.5
    sMP.phys.pne.brk1.useVarTempCalc = 0;
    sMP.phys.pne.brk2.useVarTempCalc = 0;
    sMP.phys.pne.brk3.useVarTempCalc = 0;
    sMP.phys.pne.brk4.useVarTempCalc = 0;
    sMP.phys.pne.brkTrailer1.useVarTempCalc = 0;
    sMP.phys.pne.brkTrailer2.useVarTempCalc = 0;
    sMP.phys.pne.brkTrailer3.useVarTempCalc = 0;
end


% Output to matlab
if 1
    fprintf(var_rdyn);
end
fprintf(var);
fprintf(var_tractor);
if 1
    fprintf(var_trlr);
end
if 1
    fprintf(var_trlr02);
end

% write back to sMP structure
assignin('base','sMP',sMP)

end