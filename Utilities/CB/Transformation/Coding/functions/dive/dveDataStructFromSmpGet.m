function xDataStruct = dveDataStructFromSmpGet(sMP)
% DVEDATASTRUCTFROMSMPGET creates a structure with all data from sMP with
% fieldnames bdry, ctrl, phys, human and platform.
%
% Syntax:
%   xDataStruct = dveDataStructFromSmpGet(sMP)
%
% Inputs:
%   sMP - structure: DIVe sMP structure 
%
% Outputs:
%   xDataStruct - structure with fields: 
%       .bdry - structure:  parameter and port data from boundary
%       .ctrl - structure:  parameter and port data from control
%       .human - structure: parameter and port data from human
%       .phys - structure:  parameter and port data from physics
%       .pltm - structure:  parameter and port data from platform
%
% Example: 
%   xDataStruct = dveDataStructFromSmpGet(sMP)
% 
%
% Author: Elias Rohrer, TT/XCF, Daimler Truck AG
%  Phone: +49-160-8695728
% MailTo: elias.rohrer@daimlertruck.com
%   Date: 2023-02-08

%% get data from sMP

% get boundary data
if isfield(sMP,'bdry')
    xDataStruct.('bdry') = sMP.('bdry');
else
    xDataStruct.('bdry') = struct([]);
end

% get control data
if isfield(sMP,'ctrl')
    xDataStruct.('ctrl') = sMP.('ctrl');
else
    xDataStruct.('ctrl') = struct([]);
end

% get human data
if isfield(sMP,'human')
    xDataStruct.('human') = sMP.('human');
else
    xDataStruct.('human') = struct([]);
end

% get physics data
if isfield(sMP,'phys')
    xDataStruct.('phys') = sMP.('phys');
else
    xDataStruct.('phys') = struct([]);
end

% get platfrom data
if isfield(sMP,'pltm')
    xDataStruct.('pltm') = sMP.('pltm');
else
    xDataStruct.('pltm') = struct([]);
end

return