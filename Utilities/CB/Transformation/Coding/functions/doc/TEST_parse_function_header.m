close all
clear
clc

%% define testes

cTestStringHeader = {
'function foo(in1)';
'function foo(in1,in2)';
'function foo(in1,varargin)';
'function foo(varargin)';
'function out1 = foo';
'function [out1] = foo';
'function [out1,out2] = foo';
'function [out1,varargout]';
};


%% run tests

for nTest=1:numel(cTestStringHeader)
    [inputs, outputs, function_name] = parse_function_header(cTestStringHeader{nTest});
end
