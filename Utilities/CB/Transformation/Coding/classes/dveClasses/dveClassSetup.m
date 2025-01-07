classdef dveClassSetup < handle
    
    properties (SetAccess = private, GetAccess = public)
        
     	% name of module setup in DIVe config
        sName = '';
        
        % context of module
        sContext = '';
        
        % species of module
        sSpecies = '';
        
        % family of module
        sFamily = '';
        
        % type of module
        sType = '';
        
        % variant of module setup
        sVariant = '';
        
        % model set of module setup
        sModelSet = '';
        
        % execution tool of model set
        sExecTool = '';
        
        % authoring tool of model set
        sAuthorTool = '';
        
        % co-simulation type of model set
        sCosimType = '';
        
        % file extension of model set execution file
        sFileExt = '';
        
        % bit version of model set
        sBitVersion = '';
        
        % init order of module in DIVe config
        vInitOrder = [];
        
        % max step size of module
        vStepSize = [];
        
        % user config string of model set
        sUserConfig = '';
        
        % position of model setup in DIVe sMP structure
        sSmpPos = [];
        
    end
    
    % =====================================================================
    
    properties (Access = private)
        
        % transformation constants
        CONST = cbtClassTrafoCONST.empty;
        
        
        
    end % private properties
    
    % =====================================================================
    
    properties (Constant, Access = private)
        
        
        
    end % private constant properties
    
    % =====================================================================
    
    
end % dveClassSetup