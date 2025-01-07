function pnt_Cnfg_V1(sPath,sFilename)

%  Author: Partha Pratim Mitra, RD I/TBP, MBRDI
%  Phone: +9180-6149-8223
%  MailTo: partha.mitra@daimler.com
if isempty(sPath)
    return;
end
sWS_matFile = dir([sPath,'\WS*.mat']);
cWs = dirPattern(sPath,'WS*.mat','file');
cWs = sort(cWs);
if isempty(cWs)
    return
end
xLoad = load(fullfile(sPath,cWs{end}),'sMP');
if sum(strcmp(fieldnames(xLoad),'sMP'))>0.5
    sMP = xLoad.sMP;
else
    return
end
clear xLoad
if ~isempty(upfConfigurationGet(sMP,'env','road'))
    cHdrOut{2,2} = upfConfigurationGet(sMP,'env','road');
else
    cHdrOut{2,2} = 'NA';
end
if ~isempty(upfConfigurationGet(sMP,'mec','aero'))
    cHdrOut{3,2} = upfConfigurationGet(sMP,'mec','aero');
else
    cHdrOut{3,2} = 'NA';
end
nPayloadKg = 0.0; % Initialising payload variable with 0
if (~isempty(upfConfigurationGet(sMP,'mec','mass'))&& ~isempty(upfConfigurationGet(sMP,'mec','massLoad')))
    dFlag_Trlr = 0;
    sPayLd = upfConfigurationGet(sMP,'mec','mass');% Getting the tonnage info
    sVehConfg = upfConfigurationGet(sMP,'mec','massLoad');% Getting the vehicle config info
    sExp = ['\d+[t]\d*'];
    [dLoc_strt dLoc_end] = regexp(sPayLd,sExp,'start','end');
    dIdxTrl = regexp(sVehConfg,'trl3');
    if isempty(dIdxTrl)
        dFlag_Trlr = 0;
    else
        dFlag_Trlr = 1;
    end
    if(~isempty(dLoc_strt))&&(~isempty(dLoc_end))
        if (dLoc_end-dLoc_strt)>=1
            sPayLd_RawExp = sPayLd(dLoc_strt:dLoc_end);
            sExp_Split = regexp(sPayLd_RawExp,'t','split');
            if (~isempty(sExp_Split{1,2}))&&(dFlag_Trlr == 1)
                cHdrOut{4,2} = [sExp_Split{1,1},'.',sExp_Split{1,2},'t with Trailer'];
                nPayloadKg = str2num([sExp_Split{1,1},'.',sExp_Split{1,2}])*1000; % Converting payload to kg
            elseif (~isempty(sExp_Split{1,2}))&&(dFlag_Trlr == 0)
                cHdrOut{4,2} = [sExp_Split{1,1},'.',sExp_Split{1,2},'t without Trailer'];
                nPayloadKg = str2num([sExp_Split{1,1},'.',sExp_Split{1,2}])*1000; % Converting payload to kg
            elseif (isempty(sExp_Split{1,2}))&&(dFlag_Trlr == 1)
                cHdrOut{4,2} = [sExp_Split{1,1},'t with Trailer'];
                nPayloadKg = str2num(sExp_Split{1,1})*1000; % Converting payload to kg
            elseif (isempty(sExp_Split{1,2}))&&(dFlag_Trlr == 0)
                cHdrOut{4,2} = [sExp_Split{1,1},'t without Trailer'];
                nPayloadKg = str2num(sExp_Split{1,1})*1000; % Converting payload to kg
            end
        else
            cHdrOut{4,2} = sPayLd;
        end
    else
        cHdrOut{4,2} = sPayLd;
    end
else
    cHdrOut{4,2} = 'NA';
end
clear sPayLd dLoc_strt dLoc_end sExp sPayLd_RawExp sExp_Split sTrlrInfo_Loc dFlag_Trlr
if ~isempty(upfConfigurationGet(sMP,'eng','mainData'))
    cHdrOut{5,2} = upfConfigurationGet(sMP,'eng','mainData');
else
    cHdrOut{5,2} = 'NA';
end
if ~isempty(sMP.ctrl.mcm.sys_can_performance_class_1m)
    EngPowRatng = sMP.ctrl.mcm.sys_can_performance_class_1m;
    cHdrOut{6,2} = [num2str(EngPowRatng),'kW'];
else
    cHdrOut{6,2} = 'NA';
end
clear EngPowRatng
if ~isempty(upfConfigurationGet(sMP,'mcm','mainData'))
    cHdrOut{7,2} = upfConfigurationGet(sMP,'mcm','mainData');
else
    cHdrOut{7,2} = 'NA';
end
if ~isempty(upfConfigurationGet(sMP,'eng','Fuel'))
    cHdrOut{8,2} = upfConfigurationGet(sMP,'eng','Fuel');
else
    cHdrOut{8,2} = 'NA';
end
if ~isempty(upfConfigurationGet(sMP,'acm','mainData'))
    cHdrOut{9,2} = upfConfigurationGet(sMP,'acm','mainData');
else
    cHdrOut{9,2} = 'NA';
end
if ~isempty(upfConfigurationGet(sMP,'eats','paramGlobal'))
    cHdrOut{10,2} = upfConfigurationGet(sMP,'eats','paramGlobal');
elseif ~isempty(upfConfigurationGet(sMP,'eats','mainData'))
    cHdrOut{10,2} = upfConfigurationGet(sMP,'eats','mainData');
else
    cHdrOut{10,2} = 'NA';
end

if ~isempty(upfConfigurationGet(sMP,'eats','ExhPipe'))
    cHdrOut{11,2} = upfConfigurationGet(sMP,'eats','ExhPipe');
elseif ~isempty(upfConfigurationGet(sMP,'eats','ExhPiping'))
    cHdrOut{11,2} = upfConfigurationGet(sMP,'eats','ExhPiping');
else
    cHdrOut{11,2} = 'NA';
end
if ~isempty(upfConfigurationGet(sMP,'tcm','main'))
    cHdrOut{12,2} = upfConfigurationGet(sMP,'tcm','main');
else
    cHdrOut{12,2} = 'NA';
end
if ~isempty(sMP.platform.user.computername)
    cHdrOut{13,2} = sMP.platform.user.computername;
else
    cHdrOut{13,2} = 'NA';
end
if ~isempty(sMP.platform.version)
    cHdrOut{14,2} = sMP.platform.version;
else
    cHdrOut{14,2} = 'NA';
end

if ~isempty(sMP.cfg.Configuration.creator)
    cHdrOut{15,2} = sMP.cfg.Configuration.creator;
else
    cHdrOut{15,2} = 'NA';
end
if ~isempty(sMP.platform.datestr)
    cHdrOut{16,2} = sMP.platform.datestr;
else
    cHdrOut{16,2} = 'NA';
end
clear sMP
load(sFilename,'Trip_Distance','Trip_Time');
if exist('Trip_Distance')
    if ~isempty(Trip_Distance)
        Trip_Distance_km = Trip_Distance/1000;% converting m to km
        cHdrOut{17,2} = [num2str(Trip_Distance_km),'km'];
    else
        cHdrOut{17,2} = 'NA';
    end
else
    fprint('\n Trip Distance not available. \n');
end
if exist('Trip_Time')
    if ~isempty(Trip_Time)
        Trip_Time_hr = Trip_Time/3600;% converting seconds to hour
        cHdrOut{18,2} = [num2str(Trip_Time_hr),'hour'];
    else
        cHdrOut{18,2} = 'NA';
    end
else
    fprint('\n Trip Distance not available. \n');
end
cHdrOut{1,1} = 'Parameter'; cHdrOut{1,2} = 'Value';
cHdrOut{2,1} = 'Route'; cHdrOut{3,1} = 'Vehicle';
cHdrOut{4,1} = 'Payload'; cHdrOut{5,1} = 'Engine';
cHdrOut{6,1} = 'Power Rating'; cHdrOut{7,1} = 'MCM_CALIBRATION';
cHdrOut{8,1} = 'Fuel Type'; cHdrOut{9,1} = 'ACM_CALIBRATION';
cHdrOut{10,1} = 'EATS'; cHdrOut{11,1} = 'ExhPipe';
cHdrOut{12,1} = 'Transmission';
cHdrOut{13,1} = 'Blade'; cHdrOut{14,1} = 'Build';
cHdrOut{15,1} = 'Engineer'; cHdrOut{16,1} = 'Date';
cHdrOut{17,1} = 'Trip Distance'; cHdrOut{18,1} = 'Trip Time';
save(sFilename,'cHdrOut','nPayloadKg','-append');
return

% =========================================================================

function sValue = upfConfigurationGet(sMP,sModule,sDataClass)
sValue = '';
cSetup = {sMP.cfg.Configuration.ModuleSetup.name};
bModule = ~cellfun(@isempty,regexp(cSetup,['^' sModule '\d*' '$' ],'once'));
if ~any(bModule)
    return
end
xSetup = sMP.cfg.Configuration.ModuleSetup(bModule);
cClass = {xSetup.DataSet.className};
bClass = ~cellfun(@isempty,regexp(cClass,['^' sDataClass],'once'));
if ~any(bClass)
    return
end
sValue = xSetup.DataSet(bClass).variant;
return

