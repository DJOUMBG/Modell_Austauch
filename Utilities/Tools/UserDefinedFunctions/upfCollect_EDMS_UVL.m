function upfCollect_EDMS_UVL(sPath)
% UPFCOLLECT_EDMS_UVL example function to retrieve data from a DIVe MB
% simulation and different outputs and pass it to an Excel sheet.
%
% Syntax:
%   upfCollect_EDMS_UVL(sPath)
%
% Inputs:
%   sPath - string with path of simulation run
%
% Outputs:
%
% Example: 
%   upfCollect_EDMS_UVL(pwd)
%
% Subfunctions: upfAttributeGet, upfConfigurationGet, upfSourceGet
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2018-11-19


% get base data from simulation directory
[sMP,xAttribute] = upfSourceGet(sPath);




% init cell for Excel output
cExcelOut = cell(99,2); 

% example for getting data from sMP data of module
vValue = structValueDefault(sMP,'sMP.ctrl.mcm.tbf_trq_max_r0_2m',0); % get lookup vector
% if MCM dataset values are missing, they need to be added in SIL support set for extraction from A2L -> Andre Overfeld 
cExcelOut{3,1} = 'tbf_trq_max_r0_2m';
cExcelOut{3,2} = sprintf('%i ',vValue'); % create blank separated string from vector

% example for getting data from configuration selection
cExcelOut{4,1} = 'Text full cycle';
cExcelOut{4,2} = upfConfigurationGet(sMP,'mec','lookup');

% example for gettint data from xAttribute
cExcelOut{5,1} = 'CMPROG_A';
cExcelOut{5,2} = upfAttributeGet(xAttribute,'CMPROG_A');




xlswrite(fullfile(sPath,'DummyUvlWrite.xlsx'),cExcelOut);




% example of xAttribute value
% (generated on StoreToDisc Output with MVA instrumentation from
%  phys.eng.detail.gtfrm dataset extension + some parsing on
%  phys.mec.lookup.eng dataset name) 
%     'PRSTNR'             'DIVeMB'                                                  
%     'CVPROG'             'B0040c00'                                                
%     'CMPROG_A'           'WHTC'                                                    
%     'BRBLMA'             '00001'                                                   
%     'ZLA'                '1'                                                       
%     'D'                  [                                                     110]
%     'D1'                 [                                                     130]
%     'D2'                 [                                                      65]
%     'D2S'                [                                                     120]
%     'D2V'                [                                                     100]
%     'D31'                [                                                      45]
%     'D32'                [                                                      45]
%     'D4'                 [                                                      56]
%     'DAB'                [                                                      90]
%     'DAN'                [                                                     130]
%     'DT'                 [                                                      53]
%     'DV'                 [                                                      62]
%     'EPS'                [                                                 17.8000]
%     'HU'                 [                                                   43000]
%     'MOTID'              '934ES9995'                                               
%     'S'                  [                                                     135]
%     'Z'                  [                                                       4]
%     'nox_mlp'            [                                                       1]
%     'MessBeginn'         '20181119125047'                                          
%     'MessEnde'           '20181119125047'                                          
%     'TEXT01'             'WHTC '                                                   
%     'TEXT03'             'OM934STC_130kW_ED3938_BB2976_PEMScity_TMHconst_ur0jac232'
%     'TEXT04'             'EU6'                                                     
%     'XDATSNEE'           'S_0454100_C6D1_210D_CK01_MDES_SaVE_SCS210'               
%     'XDATSAEE'           'X_M141105_CBN211LF226_prelim01_OM934STCEU6_115kW_TMH'    
%     'TEXT05'                                                           [1x130 char]
%     'Columnseparator'    ';'                                                       
%     'Channelname'        '$1'                                                      
%     'Unit'               '$2'                                                      
%     'Datatype'           '$3'             
return

% =========================================================================

function sValue = upfConfigurationGet(sMP,sModule,sDataClass)
% UPFCONFIGURATIONGET get dataset variant of specified ModuleSetup and
% DataClass.
%
% Syntax:
%   sValue = upfConfigurationGet(sMP,sModule,sDataClass)
%
% Inputs:
%          sMP - structure of DIVe parameters 
%      sModule - string with Module Setup name (or identifying front part)
%   sDataClass - string with dataset class name for dataset variant getting
%
% Outputs:
%   sValue - string with dataset variant of specified module and dataset
%
% Example: 
%   sValue = upfConfigurationGet(sMP,sModule,sDataClass)

% init output
sValue = '';

% search for module
cSetup = {sMP.cfg.Configuration.ModuleSetup.name};
bModule = ~cellfun(@isempty,regexp(cSetup,['^' sModule],'once'));
if ~any(bModule)
    fprintf(2,'Could not retrieve Module "%s" for data class "%s"',sModule,sDataClass);
    return
end
xSetup = sMP.cfg.Configuration.ModuleSetup(bModule);

% search for data class
cClass = {xSetup.DataSet.className};
bClass = ~cellfun(@isempty,regexp(cClass,['^' sDataClass],'once'));
if ~any(bClass)
    fprintf(2,'Could not retrieve data class "%s" of Module "%s"',sDataClass,sModule);
    return
end
sValue = xSetup.DataSet(bClass).variant;
return

% =========================================================================

function sValue = upfAttributeGet(xAttribute,sName)
% UPFATTRIBUTEGET get a specific name value from the attributes.
%
% Syntax:
%   sValue = upfAttributeGet(xAttribute,sName)
%
% Inputs:
%   xAttribute - structure with fields:
%         .name  - cell (1xn) with names of attributes
%         .value - cell (1xn) with values of attributes
%        sName - string with name of attribute
%
% Outputs:
%   sValue - string with value
%
% Example: 
%   sValue = upfAttributeGet(xAttribute,'CVPROG_A')

nName = find(strcmp(sName,xAttribute.name));
if ~isempty(nName)
    sValue = xAttribute.value{nName(1)};
    if isnumeric(sValue)
        sValue = num2str(sValue);
    end
    if numel(nName) > 1
        fprintf(2,['Attribute extraction: found name "%s" multiple times - ' ...
            'proceeding with first value: %s'],sName,sValue);
    end
else
    sValue = '';
end
return

% =========================================================================

function [sMP,xAttribute] = upfSourceGet(sPath)
% UPFSOURCEGET load source data from specified simulation results
% directory.
%
% Syntax:
%   [sMP,xAttribute] = upfSourceGet(sPath)
%
% Inputs:
%   sPath - string with path of simulation folder
%
% Outputs:
%          sMP - structure of DIVe parameters 
%   xAttribute - structure with fields:
%       .name  - cell (1xn) with names of attributes
%       .value - cell (1xn) with values of attributes
%
% Example: 
%   [sMP,xAttribute] = upfSourceGet(pwd)

% get sMP structure variables
cWs = dirPattern(sPath,'WS*.mat','file'); % determine workspace mat-file
cWs = sort(cWs);
xLoad = load(fullfile(sPath,cWs{end}),'sMP');
sMP = xLoad.sMP;

% get detailed data
xSource = uniread(fullfile(sPath,cWs{end}));
bMcmNorm = strcmp('MVA_MCM_norm',{xSource.subset.name});
if any(bMcmNorm)
    xAttribute = xSource.subset(bMcmNorm).attribute;
else
    xAttribute = structInit({'name','value'});
end
return