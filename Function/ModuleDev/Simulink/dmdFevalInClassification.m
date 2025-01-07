function dmdFevalInClassification(sPath,cExp,hFunction,varargin)
% DMDFEVALINCLASSIFICATION execute a defined function in folders of a
% folder tree, where on each folder level a regular expression defines the
% folders for the execution.
%
% Syntax:
%   dmdFevalInClassification(sPath,cExp,hFunction,varargin)
%
% Inputs:
%       sPath - string with path of DIVe content level of logical hierarchy
%        cExp - cell (1xn) with regular expression for each considered
%               level (context,species,family,type,[Module|Data|Support]...]
%   hFunction - handle of function to be executed, first function argument
%               needs to be a full folder path of the DIVe classification
%    varargin - further function arguments
%
% Outputs:
%
% Example: 
%   dmdFevalInClassification('C:\dirsync\06DIVe\04Transfer\ECU\MCMnew',{'^ctrl$','^mcm$','^mil$','^[EMP]\d+_\w+','^Data$','^instrument$','.+'},@dir)

% match specified paths in classification folder tree
cPath = {sPath};
for nIdxLevel = 1:numel(cExp)
    cPathNext = {};
    for nIdxPath = 1:numel(cPath)
        cPathAdd = dirPattern(cPath{nIdxPath},cExp{nIdxLevel},'folder',true);
        cPathAdd = cellfun(@(x)fullfile(cPath{nIdxPath},x),cPathAdd,'UniformOutput',false);
        cPathNext = [cPathNext cPathAdd]; %#ok<AGROW>
    end
    cPath = cPathNext;
end

% execute function on path
for nIdxPath = 1:numel(cPath)
    feval(hFunction,cPath{nIdxPath},varargin{:})
end
return
