close all
clear

cd(fileparts(mfilename('fullpath')));

%% shows substructure of trailer or trailer1 of given Simpack-Manoever

sSimpackMan = '"Y:\SIMPACK\modelle\EM_2021x_5\Fahrzeuge\truck_GZ_6xX_L-UU_Si-SiSi_tr1_ST_SiSiSi_tr2_ZAA_SiSi_V01\truck_GZ_6xX_L-UU_Si-SiSi_tr1_ST_SiSiSi_tr2_ZAA_SiSi_V01--Template--FM_DIVeMT_inStwAng_V01--Actros_T6x2_SxDU_tr1_ST3_tr2_ZAA2_60t--v1.spck"';



%% Get fzg file

sEmdbPath = 'Y:\SIMPACK\modelle\EM_2021x_5';


sSimpackMan = strrep(sSimpackMan,'"','');

sTxt = fleFileRead(sSimpackMan);
cLines = strStringToLines(sTxt);
cLinesMan = strStringListClean(cLines);


bLines = contains(cLinesMan,'substr.file');
cSubstrLines = cLinesMan(bLines);

bLines = contains(cSubstrLines,'$S_fzg');
cFzgSubstrLines = cSubstrLines(bLines);

sFzgSubstrLine = cFzgSubstrLines{1};

cSplit = strsplit(sFzgSubstrLine,'=');
sFzgFile = cSplit{2};

cSplit = strsplit(sFzgFile,'!');
sFzgFile = strtrim(strrep(cSplit{1},'''',''));


%% get trailer files

sTxt = fleFileRead(fullfile(sEmdbPath,'fzg',sFzgFile));
cLines = strStringToLines(sTxt);
cLinesMan = strStringListClean(cLines);


bLines = contains(cLinesMan,'substr.file');
cSubstrLines = cLinesMan(bLines);

bLines = contains(cSubstrLines,'trailer');
cTrailerSubstrLines = cSubstrLines(bLines);


for nTrl=1:numel(cTrailerSubstrLines)
    
    sTrlSubstrLine = cTrailerSubstrLines{nTrl};

    cSplit = strsplit(sTrlSubstrLine,'=');
    sTrlFile = cSplit{2};
    
    cSplit = strsplit(cSplit{1},'(');
    sTrlSubName = cSplit{2};
    
    sTrlSubName = strtrim(strrep(sTrlSubName,')',''));

    cSplit = strsplit(sTrlFile,'!');
    sTrlFile = strtrim(strrep(cSplit{1},'''',''));
    
    disp([sTrlSubName,': ',sTrlFile]);
    
end



