function xSubStruct = setNormStructField(xInStruct,sFieldname)

if isfield(xInStruct,sFieldname)
    xSubStruct = xInStruct.(sFieldname);
    if isempty(xSubStruct) || isempty(fieldnames(xSubStruct))
        xSubStruct = struct([]);
    end
else
    xSubStruct = struct([]);
end

end