function [xPar,cFail] = dcmRead(sFile,cParameter)
% DCMREAD read DCM parameter file and extract the specified parameters as
% structure fields. 
%
% Syntax:
%   xPar = dcmRead(sFile)
%   [xPar,cFail] = dcmRead(sFile,cParameter)
%
% Inputs:
%        sFile - string with filepath of DCM file
%   cParameter - cell (1xn) with strings of parameter names to extract
%
% Outputs:
%   xPar - structure with fields of parameter names and values of parameter 
%
% Example: 
%   [xPar] = dcmRead('X_M121103_CBN612LF195_prelim01.dcm')
%   [xPar,cFail] = dcmRead('X_M121103_CBN612LF195_prelim01.dcm',...
%       {'osg_eng_speed_max_1m','tbf_trq_max_r0_x_eng_speed','tbf_trq_max_r0_2m'})
%
% Author: Rainer Frey, TP/EAD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2017-08-21

% check input
if nargin > 1
    % ensure correct orientation of cParameter
    nSizePar = size(cParameter);
    if nSizePar(1) > nSizePar(2)
        cParameter = cParameter';
    end
end

xPar = [];

% read file into string
sCon = fileread(sFile);

% split string into item sections
cItem = regexp(sCon,'\nEND[\r\n]','split');
cItem = strtrim(cItem);

% extract parameter names
cName = cell(1,numel(cItem)-1);
for nIdxItem = 1:numel(cItem)
    cName{nIdxItem} = sscanf(cItem{nIdxItem},'%*[A-Z] %s',2);
end

% get specified parameters
if nargin > 1
    [bHit,nHit] = ismember(cParameter,cName);
    nHit = nHit(bHit);
else
    bHit = ~cellfun(@isempty,cName);
    cParameter = cName;
    nHit = find(bHit);
end

% parse specified parameters
hCmpWE = @(x)strcmp(x(1:2),'WE');
hCmpST = @(x)strcmp(x(1:3),'ST/');
hCutString = @(x)x(6:end);
for nIdxPar = nHit
    % init loop
    vPar = [];
    
    % split into lines
    ccLine = textscan(cItem{nIdxPar},'%s','delimiter','\n');
    cLine = ccLine{1};
    % clear empty lines
    nAuxFullLines = cellfun(@(x)~isempty(x),cLine);
    cLine = cLine(nAuxFullLines);
    
    % value parsing according parameter type
    sType = sscanf(cLine{1},'%[A-Z]',1);
    switch sType
        case 'FESTWERT'
            bValue = cellfun(hCmpWE,cLine);
            if any(bValue)
                sValue = cLine{bValue}(6:end);
                vPar = str2num(sValue); %#ok<ST2NM>
            else
                disp(['Warning: dcmRead -- Could not find Value for parameter ', cName{nIdxPar}]);
            end
            
        case {'KENNLINIE','GRUPPENKENNLINIE','FESTWERTEBLOCK'}
            bValue = cellfun(hCmpWE,cLine);
            cValue = cellfun(hCutString,cLine(bValue),'UniformOutput',false);
            sValue = strGlue(cValue,' ');
            vPar = str2num(sValue); %#ok<ST2NM>
            
        case 'STUETZSTELLENVERTEILUNG'
            bValue = cellfun(hCmpST,cLine);
            cValue = cellfun(hCutString,cLine(bValue),'UniformOutput',false);
            sValue = strGlue(cValue,' ');
            vPar = str2num(sValue); %#ok<ST2NM>

        case {'KENNFELD','GRUPPENKENNFELD'}
            % determine value lines and separation of matrix lines
            bValue = cellfun(hCmpWE,cLine);
            nValue = find(bValue);
            bValueDiff = diff(nValue) > 1;
            nValueDiff = find(bValueDiff);
            
            % prepare cells and matrix (pre-allocation)
            cValue = cellfun(hCutString,cLine(bValue),'UniformOutput',false);
            nValueVert = sum(bValueDiff)+1;
            sValue = strGlue(cValue(1:nValueDiff(1)),' ');
            vParTemp = str2num(sValue); %#ok<ST2NM>
            vPar = NaN(nValueVert,numel(vParTemp));
            vPar(1,:) = vParTemp;
            
            % loop through rest of lines of parameter matrix (2:end)
            nStart = nValueDiff(1)+1;
            for nIdxVert = 2:nValueVert
                if nIdxVert <= numel(nValueDiff)
                    nEnd = nValueDiff(nIdxVert);
                else
                    nEnd = numel(cValue);
                end
                sValue = strGlue(cValue(nStart:nEnd),' ');
                vPar(nIdxVert,:) = str2num(sValue); %#ok<ST2NM>
                nStart = nEnd+1;
            end
			vPar = vPar';

        otherwise
            fprintf(2,'encountered unknown type: %s\n',sType);
    end
    
    % create parameter
    if isempty(vPar)
        bFail = strcmp(cName{nIdxPar},cParameter);
        bHit(bFail) = false;
    else
        % ensure correct parameter name
        if isvarname(cName{nIdxPar})
            sParameter = cName{nIdxPar};
        else
            % fast correction on parameter name (better performance than genvarname)
            sParameter = regexprep(cName{nIdxPar},...
                {'par_op4_data_table.','par_op4_data_basic.','par_table.','par_basic.',...
                'par2_table.','par2_basic.','par_op_data_table.','par_op_data_basic.',...
                'par_sensor_blk.','sensor_bf32.',...
                '\.','\[','\]','^MU_CalClassUnion_1m_MU_CalClassStruct_',...
                '^MU_CalUnion_1m_MU_CalStruct_','^MU_CalDaiInhibitMatrix_1m_',...
                '^SAE_ReadinessGrpEnableCond_1m_'},...
                {'','','','','','','','','','','_','_','_','','','',''});
        end
        
        % create structure field for parameter
        xPar.(sParameter) = vPar;
    end
end

% state missing parameters
if any(~bHit)
    cFail = cParameter(~bHit);
    cFail = cFail(~cellfun(@isempty,cFail));
    if isempty(cFail) || nargout > 1
        return
    end
    fprintf(1,'The following parameters were not found: \n');
    for nIdxFail = 1:numel(cFail)
            fprintf(1,'  %s\n',cFail{nIdxFail});
    end
else
    cFail = {};
end
return
