function bValid = chkNanInfOfString(sValue)

% convert to double
vValue = str2double(sValue);

% check for nan or inf
if isnan(vValue) || isinf(vValue)
    bValid = true;
else
    bValid = false;
end

return