function [varargout] = fcGetCDI(varargin)
% FCGETCDI Liest das CDI Table vom PEP-SIL ein
% benötigt CDI-Table.m
%
%
% Syntax:  [xCDI, CDITable, Applications] = fcGetCDI;
% Syntax:  [xCDI, CDITable, Applications] = fcGetCDI([]);
% Syntax:  [xCDI, CDITable, Applications] = fcGetCDI('CPC');
% Syntax:  [xCDI, CDITable, Applications] = fcGetCDI('IPPC');
% Syntax:  [xCDI] = fcGetCDI([], sSignal);
% Syntax:  [xCDI, value1] = fcGetCDI(xCDI, sSignal, 'phys', RawValue);
% Syntax:  [xCDI, value1] = fcGetCDI(xCDI, sSignal, 'raw', PhysValue);
% Syntax:  [xCDI, value1, value2] = fcGetCDI(xCDI, sSignal, 'phys', RawValue, 'param', sField);
%
% Inputs:
%    varargin - siehe Syntax
%
% Outputs:
%    varargout - siehe Syntax
%
% Example: 
%    [xCDI, wert1, wert2] = fcGetCDI([], 'cal_o_AgEngSpdThreshEcoRoll_u16', 'phys', 12500, 'param', 'Unit');
%
%
% Subfunctions: fcGetDataType
% Other m-files required: CPC3_CDI_Table
%
% See also: CDI_Table
%
% Author: ploch37
% Date:   27-Jul-2012
%
% SVN: (wird automatisch gesetzt, wenn Keywords - Eigenschaft gewählt ist)
%   $Rev:: 451                                                  $
%   $Author:: ploch37                                           $
%   $Date:: 2016-11-15 15:18:34 +0100 (Di, 15. Nov 2016)        $
%   $URL: file:///Y:/300_Software/330_SVN_server/matlab_tools/branches/cpc_sil/tools/fcGetCDI.m $


%% Load CDI Table
if nargin == 0
    xCDI = [];
else
    xCDI = varargin{1};
end
if isempty(xCDI) || ischar(xCDI)
    if ischar(xCDI)
        switch upper(xCDI)
            case {'C', 'CPC', 'CPC3', 'CPC5', 'CPC3_CDI_TABLE'}
                try
                    cpc_cdi_table;
                catch
                    CPC3_CDI_Table;
                end
            case {'I', 'PPC' 'IPPC', 'IPPC_CDI_TABLE'}
                IPPC_CDI_Table;
            otherwise
                fprintf(2, 'CDI Table not defined');
                return
        end
        clear xCDI
    else
        try
            CPC3_CDI_Table;
        catch %#ok<CTCH>
            CDI_Table;
        end
    end
    n = 0;
    for k = 1:size(Signals, 1)
        % Signal Information
        % Id, Name, CodeExpression, Description, Type_ID, Dimensions, DefaultValue, ReadSignalRights, WriteSignalRights
        sName = Signals{k,2};
        n = n + 1;
        xCDI(n).Id                  = Signals{k,1};
        xCDI(n).Name                = Signals{k,2};
        xCDI(n).CodeExpression      = Signals{k,3};
        xCDI(n).Description         = Signals{k,4};
        xCDI(n).TypeID              = Signals{k,5};
        xCDI(n).Dimensions          = Signals{k,6};
        xCDI(n).DefaultValue        = Signals{k,7};
        xCDI(n).ReadSignalRights    = Signals{k,8};
        xCDI(n).WriteSignalRights   = Signals{k,9};
        % Data Type Information
        % Name, Description, Unit, IsSigned, BitLength, Factor, Offset, SNARanges, ERRRanges, OKRanges
        DataType = DataTypes(strcmp(xCDI(n).TypeID, DataTypes), :);
        if ~isempty(DataType)
            if n == 1
                % first time: generating new fields of structure
                xCDI = fcGetDataType(xCDI(n), DataType);
            else
                xCDI(n) = fcGetDataType(xCDI(n), DataType);
            end
        else
            % PID (Struct)
            StructType = StructTypes{strcmp(xCDI(n).TypeID, StructTypes), 3};
            xCDIBase = xCDI(n);
            for kk = 1: size(StructType, 1)
                n = n + 1;
                xCDI(n) = xCDIBase;
                xCDI(n).Name        = [xCDIBase.Name '.' StructType{kk,1}];
                xCDI(n).Description = StructType{kk,2};
                xCDI(n).TypeID      = StructType{kk,3};
                xCDI(n).DefaultValue = xCDIBase.DefaultValue{1}{kk};
                DataType = DataTypes(strcmp(xCDI(n).TypeID, DataTypes), :);
                if ~isempty(DataType)
                    xCDI(n) = fcGetDataType(xCDI(n), DataType);
                end
            end
        end
    end
end


%% Output information
% all information
if nargin <= 1 
    varargout{1} = xCDI;
    varargout{2} = CDITable;
    varargout{3} = Applications;
end
% one signal is defined
if nargin > 1 
    sSignal = varargin{2};
    idx = find(strcmp({xCDI.Name}, sSignal));
    if isempty(idx) % Signale von hinten suchen
        idx = find(arrayfun(@(x) strncmp(fliplr(x.Name), fliplr(sSignal), length(sSignal)), xCDI));
    end
    % Search for ptconf parameters description in signal and not in
    % structure, because not sufficient described in structure
    if ~isempty(idx) && strncmp(sSignal, 'ptconf_', 7) && length(xCDI(idx).Description) <= 1
        sSignalBackup = regexprep(sSignal, 'ptconf_\w*.', 'ptconf_g_');
        idx2 = find(strcmp({xCDI.Name}, sSignalBackup));
        if ~isempty(idx2)
            fprintf('Description of %s is replaced by %s\n', sSignal, sSignalBackup);
            xCDI(idx).Description = xCDI(idx2).Description;
            
        end
    end
    xCDI = xCDI(idx);
end
% output the signal information
if nargin > 1
    varargout{1} = xCDI;
end
% ouput special information
if nargin > 2
    for k = 3:2:nargin
        sParameter = varargin{k};
        switch sParameter
            case 'raw'
                PhysValue = varargin{k+1}; % phys. value
                varargout{(k-1)/2+1} = round((PhysValue - xCDI.Offset)/xCDI.Factor); % RAW value
            case 'phys'
                RawValue = varargin{k+1}; % RAW value
                varargout{(k-1)/2+1} = RawValue * xCDI.Factor + xCDI.Offset; % phys. value
            case 'param'
                sField = varargin{k+1}; % Fieldname
                varargout{(k-1)/2+1} = xCDI.(sField);
            otherwise
                error('wrong parameter')
        end
    end
end


function [xCDI] = fcGetDataType(xCDI, DataType)
xCDI.TypeDescription = DataType{2};
xCDI.Unit            = DataType{3};
xCDI.IsSigned        = DataType{4};
xCDI.BitLength       = DataType{5};
xCDI.Factor          = DataType{6};
xCDI.Offset          = DataType{7};
xCDI.SNARanges       = DataType{8};
xCDI.ERRRanges       = DataType{9};
xCDI.OKRanges        = DataType{10};
% Further Information
xCDI.DefaultValuePhys = xCDI.DefaultValue * xCDI.Factor + xCDI.Offset;
