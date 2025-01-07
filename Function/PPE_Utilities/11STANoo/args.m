classdef args < dynamicprops
% ARGS parse parameter value pairs and patch with default values
% Parse a varargin cell array for predefined parameter value pairs
% and patch not addressed parameters with default values.
% Parameter names are handled case insensitive.
% Non-conform/not processed arguments are exposed in arg.rest method.
% Use parsed parameters by oArg = args, oArg.<parameterField>
%
% Inputs:
%   cArgDefault - cell (mx3) with
%                   (m,1) - string with argument parameter name
%                   (m,2) - default value of argument
%                   (m,3) - [optional] string with variable name of
%                           argument in cell (otherwise = (m,1))
%      varargin - cell with arbitrary numer of parameter & value pairs
%
% Example:
%   oArg = args({'Arg1','StringValue','sArg1';'Arg2',3,[]},varargin{:}) % $noTest
%   oArg = args({'Arg1','StringValue','sArg1';'Arg2',3,[]},'arg1','bla','aRG2',2) % $[1]single
%   oArg = args({'WindowState',-1,'nWindowState';... % $[2]multiline
%              'Priority','normal',[];... % $[2]multiline
%              'Title','process',[];... % $[2]multiline
%              'TimeOut',10,[]},varargin{:}); % $[2]multiline
%
% See also: parseArgs
%
% Author: Rainer Frey, TP/EAF, Daimler Truck AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2021-05-12

    properties (Access = private)
        cPropertyField
        cPropertyParameter
        cRest
    end
    
    properties (Access = public)
        
    end
    
    % *********************************************************************
    
    methods (Access = private)
        
        function oThis = init(oThis,cArgDefault)
            %INIT add default properties with default values
            
            % store property alias
            oThis.cPropertyParameter = cArgDefault(:,1);
            oThis.cPropertyField = cArgDefault(:,3);
            
            % initialization with default structure
            for nIdxArg = 1:size(cArgDefault,1)
                if isempty(cArgDefault{nIdxArg,3}) % no variable/field name specified
                    sPropertyDynamic = cArgDefault{nIdxArg,1};
                else % use specific variable name
                    sPropertyDynamic = cArgDefault{nIdxArg,3};
                end
                oThis.addprop(sPropertyDynamic); % create dynamic property
                oThis.(sPropertyDynamic) = cArgDefault{nIdxArg,2}; % assign default value
            end
        end
        
        % =================================================================
        
        function oThis = parse(oThis,cVarargin)
            %PARSE parse values of valid parameters into properties
            
            % parse arguments for parameter value pairs
            nIdxArg = 1;
            nRest = [];
            while nIdxArg < numel(cVarargin)
                [bValid,nID] = ismember(lower(cVarargin{nIdxArg}),lower(oThis.cPropertyParameter));
                if bValid % argument valid
                    if isempty(oThis.cPropertyField{nID}) % no variable/field name specified
                        oThis.(oThis.cPropertyParameter{nID}) = cVarargin{nIdxArg+1};
                    else
                        oThis.(oThis.cPropertyField{nID}) = cVarargin{nIdxArg+1}; 
                    end
                    nIdxArg = nIdxArg + 2;
                else
                    % no match - mark argument for "rest"
                    nRest = [nRest nIdxArg]; %#ok<AGROW>
                    nIdxArg = nIdxArg + 1;
                end % if argument valid
            end % for each argument pair
            
             
            % collect final rest argument
            if nIdxArg == numel(cVarargin)
                nRest = [nRest nIdxArg];
            end
            
            % prepare "rest" argument cell
            oThis.cRest = cVarargin(nRest);            
        end
        
        % =================================================================
        
        function cRest = rest(oThis)
            %REST expose non-matched arguments, while hiding in properties
            cRest = oThis.cRest;
        end
        
    end
        
    % *********************************************************************
        
    methods (Access = public)
        
        function oThis = args(cArgDefault,varargin) % Constructor
            %ARGS parses parameter value pairs of function interfaces
            %   Detailed explanation goes here
            
            % initialize properties and default values
            oThis.init(cArgDefault);
            
            % parse function arguments
            oThis.parse(varargin);
        end
       
    end
end