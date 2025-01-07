function [c] = fcChangeDiwaParam(c, sParNames, sPar, dValue)
% FCCHANGEDIWAPARAM change of DIWA Parameters
%
%
% Syntax:  [c] = fcChangeDiwaParam(c, sParNames, sPar, dValue)
%
% Inputs:
%            c - [] double array of the Parameter Values
%    sParNames - [''] char array of the Parameter Names
%         sPar - [''] Parameter Name
%       dValue - [] New Value
%
% Outputs:
%    c - [{}] Cell Array of the Parameter Values
%
% Example: 
%    DIWA_BB_ParValues = fcChangeDiwaParam(DIWA_BB_ParValues, DIWA_BB_ParNames, 'mVeh', mdl.v.m/1000);
%    DIWA_BB_ParValues = fcChangeDiwaParam(DIWA_BB_ParValues, DIWA_BB_ParNames, 'etaAxle', mdl.a.eta);
%
%
% Author: ploch37
% Date:   07-Apr-2015
%
% SVN: (is set automatically, if Keywords - Property enabled)
%   $Rev:: 80                                                   $
%   $Author:: ploch37                                           $
%   $Date:: 2015-04-07 15:01:35 +0200 (Di, 07. Apr 2015)        $
%   $URL: file:///Y:/300_Software/330_SVN_server/Voith_PEPSIL/trunk/SIL_Environment/Example/fcChangeDiwaParam.m $

%% ------------- BEGIN CODE --------------

% find position
sParNames = deblank(num2cell(sParNames, 2));
idx = find(strcmp(sParNames, sPar));

% change parameter
if ~isempty(idx)
    dValueOld = c(idx);
    if ~exist('dValue', 'var')
        c = [];
        fprintf(1, '%s: %g\n', sPar, dValueOld);
        return
    end
    if dValueOld ~= dValue
        c(idx) = dValue;
        fprintf(1, '%s changed from %g to %g\n', sPar, dValueOld, dValue);
    end
else
    fprintf(2, '%s not found\n', sPar);
end