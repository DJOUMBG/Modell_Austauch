function cLines = strStrToLineByWhitespace(sTxt)

% split at whitespaces
cSplit = strsplit(sTxt,{'\n','\r','\t','\v','\b',' ',});
cLines = strStringListClean(cSplit);

end