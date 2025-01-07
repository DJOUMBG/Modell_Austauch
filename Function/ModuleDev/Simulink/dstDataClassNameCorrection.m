 function dstDataClassNameCorrection(sXml,cAlias)
% DSTDATACLASSNAMECORRECTION apply corrections on a DIVe Module XML
% regardings dataset, which are derived from one dataset classType by
% different dataset classNames.
%
% Syntax:
%   dstDataClassNameCorrection
%   dstDataClassNameCorrection(sXml)
%   dstDataClassNameCorrection(sXml,cAlias)
%
% Inputs:
%     sXml - string with filepath of the Module XML to be corrected
%   cAlias - cell (mx2) with
%               {m,1}: string with Dataset classType 
%               {m,2}: cell of strings with alias names for this DataSet
%                      classType -> will become new Dataset classNames
%
% Outputs:
%
% Example: 
%   dstDataClassNameCorrection(sXml)
%   dstDataClassNameCorrection(sXml,{'axle',...
%       {'axle1','axle2','axle3','axle4','trailerAxle1','trailerAxle2','trailerAxle3'}})
%
% See also: dsxRead, dsxWrite
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-09-27

% input check
if nargin < 1
    [sFile,sPath] = uigetfile( ... % file selelction for simulink model
        {'*.xml','DIVe Module XML (*.xml)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'Select DIVe Module XML',...
        'MultiSelect','off');
    if isnumeric(sFile) % cancel in model file selection
        disp('Simulink model selection canceled - block missing! Stopped...')
        return
    end
    sXml = fullfile(sPath,sFile);
end
if nargin < 2
    cAlias = {'axle',{'axle1','axle2','axle3','axle4','trailerAxle1','trailerAxle2','trailerAxle3'};
              'brk',{'brk1','brk2','brk3','brk4','trailerBrk1','trailerBrk2','trailerBrk3'};
              'sht',{'shtF','shtR'};
              'wheel',{'wheel1','wheel2','wheel3','wheel4','trailerWheel1','trailerWheel2','trailerWheel3'};
              'auxEmot',{'auxEmotAcCompFront','auxEmotAcCompRear','auxEmotAirComp',};
              'auxInverter',{'API1','API2','API3','DCL1','DCL2',};
              'aux_power_selector',{'aux_power_selector',};
              'drvEmot',{'drvEmot',};
              'poweredaxles',{'poweredaxles'};
              'brakeresistors',{'brakeresistors'};...
             };
end

% read Module XML
xTree = dsxRead(sXml);

% expand master classType into className instances
for nIdxAlias = 1:size(cAlias,1)
    % determine classType with Module XML
    bAlias = strcmp(cAlias{nIdxAlias,1},{xTree.Module.Interface.DataSet.classType});
    if ~any(bAlias)
        fprintf(1,['dstDataClassNameCorrection: The dataset classType "%s" ' ...
            'is not in the specified Module XML of %s.%s.%s.%s.Module.%s\n'],...
            cAlias{nIdxAlias,1},xTree.Module.context,xTree.Module.species,...
            xTree.Module.family,xTree.Module.type,xTree.Module.name);
        continue
    end
    
    % concatenate new dataset structure, while preserving position of original classType 
    nAlias = find(bAlias);
    xData = xTree.Module.Interface.DataSet(1:nAlias-1); % datasets before alias
    % copy classType to classNames
    for nIdxName = 1:numel(cAlias{nIdxAlias,2})
        xData = structConcat(xData,xTree.Module.Interface.DataSet(nAlias));
        xData(end).className = cAlias{nIdxAlias,2}{nIdxName};
        xData(end).isSubspecies = '1';
    end
    xData = structConcat(xData,xTree.Module.Interface.DataSet(nAlias+1:end)); % datasets after alias
    xTree.Module.Interface.DataSet = xData;
end

% write XML file again
dsxWrite(sXml,xTree);
fprintf(1,'... dataset className correction is done.\n');
return
