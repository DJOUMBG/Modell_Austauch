function str = searchstring2regexp(str)
% searchstring2regexp - converts a search string with asterix(*) as
% wildcard into a regexp string
% 
% Input variables:
% str   - string with search pattern e.g. 'T_DPF_01*b'
% 
% Output variables:
% str   - string with regular expression to search for search pattern
% 
% Example calls:
% str = searchstring2regexp(str)
% str = searchstring2regexp('T_DPF_01*b') % produces: ^T_DPF_01.*b$

if isempty(str)
    return
end

% handle special characters
specialcharacters = '\.[]()|?#^$!=+';
for k = 1:length(specialcharacters)
    str = regexprep(str,['\' specialcharacters(k)],['\\\' specialcharacters(k)]);
end

% handle fix start and end
if ~strcmp(str(1),'*')
    str = ['^' str];
end
if ~strcmp(str(end),'*')
    str = [str '$'];
end

wildcard = '*';
str = regexprep(str,['\' wildcard],['\.\' wildcard]);
return