function sConfigParamResolve = silGetConfigParamResolve(sConfigParamName)

sConfigParamResolve = sprintf('${%s}',sConfigParamName);

return