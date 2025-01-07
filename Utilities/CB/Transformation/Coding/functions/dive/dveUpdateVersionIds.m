function xSetup = dveUpdateVersionIds(xSetup,sWorkspaceContent)

xSetup = dveConfigVersionIdGet(xSetup,sWorkspaceContent,true);
xSetup = dcsFcnStructVersionId(xSetup,true);

return