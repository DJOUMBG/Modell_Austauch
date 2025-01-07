classdef testClass_startDIVeCodeBased < matlab.unittest.TestCase
    
    properties (Constant, Access = private)
        % define local testcase paths
        sStdTestcase01 = 'Configuration\Vehicle_Other\DIVeCBdev\devCB_minimal_sfcn.xml';
    end
    
    % =====================================================================
    
    properties (GetAccess = public, SetAccess = private)
        
        % workspace root given by user
        sWorkspaceRoot = '';
        
        % path of testcase 1 relative to workspace root
        sTestcasePath01 = '';
        
    end % properties
    
    % =====================================================================
    
    methods
        
        function testObj = testClass_startDIVeCodeBased(sWorkspaceRoot)
            
            % check input argument workspace root folder
            testObj.sWorkspaceRoot = sWorkspaceRoot;
            if ~exist(testObj.sWorkspaceRoot,'dir')
                error('Workspace root folder "%s" does not exist.',...
                    testObj.sWorkspaceRoot);
            end
            
            % check if testcase file exists
            testObj.sTestcasePath01 = fullfile(testObj.sWorkspaceRoot,...
                testObj.sStdTestcase01);
            if ~exist(testObj.sTestcasePath01,'file')
                error('Testcase file "%s" does not exist.',...
                    testObj.sTestcasePath01);
            end
            
        end
        
    end % methods
    
    % =====================================================================
    
    methods(TestMethodSetup)
        
        function addWorkspacePath(testObj)
            addpath(testObj.sWorkspaceRoot);
        end % addWorkspacePath
        
    end % TestMethodSetup
    
    % =====================================================================
    
    methods(TestMethodTeardown)
        
        function rmWorkspacePath(testObj)
            rmpath(testObj.sWorkspaceRoot);
        end % rmWorkspacePath
        
    end % TestMethodTeardown
    
    % =====================================================================
    
    methods(Test)
        
        function transformWithoutStartType(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01);
        end
        
        % =================================================================
        
        function openTestcase(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,0);
        end
        
        % =================================================================
        
        function runTestcase(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,1);
        end
        
        % =================================================================
        
        function runSilentTestcase(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,2);
        end
        
        % =================================================================
        
        function transformTestcase(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,3);
        end
        
        % =================================================================
        
        function transformTestcaseWithShortName(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,3,'','shortName',true);
        end
        
        % =================================================================
        
        function transformTestcaseWithDebugMode(testObj)
            startDIVeCodeBased(testObj.sTestcasePath01,3,'','debugMode',true);
        end
        
    end % Test
    
end