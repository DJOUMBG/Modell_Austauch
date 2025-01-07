function  pnt_CreatePowerpoint(sPathFull)
%pnt_CreatePowerpoint Exports the Summary values and figures generated to
% Syntax:
%   pnt_CreatePowerpoint(sResultPath)
%
%
% Inputs:
%       sResultPath - String with complete path of the results folder
% Outputs:
%
% Example:
%   pnt_CreatePowerpoint('D:\ajchand\drm_0049\tmp\210306_233522_EU_Atego_L_...
%   1024_PEMS_4x2_PEMS_2013_NGA_detPP_8t_Case09_AJCHAND\B48_EU_Atego_L_1024...
%   _PEMS_4x2_PEMS_2013_NGA_detPP_8t_Case09_PEMSNOX_Data.mat')
%
% Original Script given by Mohan Boyapati, RDI/TBP MBRDI, modified and adapted for the
% intended use
%
% Author: Ajesh Chandran, TT/SIP, DTICI
%  Phone: +91-80-6149-6368
% MailTo: ajesh.chandran@daimler.com
%   Date: 2020-02-26

%% Getting the list of figure files generated
[sResultPath,~,~] = fileparts(sPathFull); % Getting the folder location
cListFigures = dirPattern(sResultPath,'^NP_.+\.png$','file',true);
sPathTemplate =pwd;% Assigning the present working directory which is the result folder
if exist(fullfile(sPathTemplate,'Template.pptx'))% Template present in pwd
    sPathTemplate = fullfile(sPathTemplate,'Template.pptx');
else % pwd will be result folder and template.pptx is absent
    sPathTemplate = sPathTemplate(1:(strfind(sPathTemplate,'tmp')-2)); % Extracting the build path
    if exist(fullfile(sPathTemplate,'Utilities\Tools\UserDefinedFunctions\PEMS\Template.pptx'))
        sPathTemplate =fullfile(sPathTemplate,'Utilities\Tools\UserDefinedFunctions\PEMS\Template.pptx'); 
    else %Template file missing. Cant create the ppt
        fprintf('\n Template for PPT creation missing');
        return;
    end
end

hPowerpoint = actxserver('PowerPoint.Application');% Create an ActiveX object
hPowerpoint.Visible = 1;% make powerpoint visible
hPowerpoint.Presentations.invoke;% activate presentations
hPresentation = hPowerpoint.Presentations.Open(sPathTemplate); % Open the template
hPresentation.SaveAs(fullfile(sResultPath,'PEMS_NOx_Report.pptx'));% saveas presentation
hPresentation.Slides.invoke; % activate slides
hSampleSlide = hPresentation.SlideMaster.CustomLayouts.Item(3);% take empty template slide with title only

nSlide = hPresentation.Slides.Count; % Number of slides
while nSlide ~= 0 % For deleting extra slides if present
    hPresentation.Slides.Item(1).Delete;
    nSlide = hPresentation.Slides.Count;
end

pnt_TableCnfg(hPresentation,hSampleSlide,sPathFull);
pnt_Tableadd(hPresentation,hSampleSlide,sPathFull); % function to add table to the presentation
pnt_FigureAdd(hPresentation,cListFigures,hSampleSlide,sResultPath); % function to add figures to slide
hPresentation.Save; % Saving the presentation
hPresentation.SaveCopyAs(fullfile(sResultPath,'PEMS_NOx_Report.pdf'),32);
% pause(2);
hPowerpoint.Quit;
% pause(2);
hPowerpoint.delete;
fprintf('\nSummary Presentation created.\n');
end

%% Function to add figures to powerpoint
function pnt_FigureAdd(hCurrentPpt,cListFigures,hSampleSlide,sPath)
for nIdx = 1:numel(cListFigures)
    sTitleFig = cListFigures{nIdx}(7:end-4); % Title for the slide
    nSlide = hCurrentPpt.Slides.Count; % Number of slides in presentation
    hCurrentSlide = hCurrentPpt.Slides.AddSlide(nSlide+1,hSampleSlide); % Adding new slide using sample slide
    pause(0.1); % Time gap for the slide creation
    hCurrentSlide.Select; % Selecting the current slide
    hPicture=hCurrentSlide.Shapes.AddPicture(fullfile(sPath,cListFigures{nIdx}),'msoFalse','msoTrue', 35,70);
    hPicture.ScaleWidth(0.5,'msoTrue');% Default for 100% scaling
    %hPicture.ScaleWidth(0.685,'msoTrue');% for 125% scaling old
    %hPicture.ScaleWidth(0.8,'msoTrue');% for 125% scaling new
    hCurrentSlide.Shapes.Title.TextFrame.TextRange.Text = sTitleFig;% Adding the Title text to the slide
    hCurrentSlide.HeadersFooters.Footer.Text = ['PEMSNOX_Evaluation Summary |TT/S43 TT/XCD|',date];% Adding footer
    
end
end

%% Function to add table to Powerpoint
function pnt_Tableadd(hCurrentPpt,hSampleSlide,sPathFull)

[sResultPath,~,~] = fileparts(sPathFull); % Getting the folder location
load(sPathFull,'xTable'); % Loading the Table to be printed
nSlide = hCurrentPpt.Slides.Count; % Getting the number of slides in the ppt
hCurrentSlide = hCurrentPpt.Slides.AddSlide(nSlide+1,hSampleSlide); % Adding new slide
hCurrentSlide.Select; % Selecting the newly added slide
nRow = 19; %numel(xTable.VarName)+1; % Num of rows + title row
nColumn = 2; % Col1 Variable Name Col2 Value
hCurrentTable = hCurrentSlide.Shapes.AddTable(nRow,nColumn,60,80,400,60);% ...
%(nRow,nColumn,xcordinate of table start,y of table start
%width ot the table and height of the table
%hCurrentTable.Table.Rows.Item(3).Height = 5;% to change height of
%individual row
% for nIdx = 1:nRow
%    hCurrentTable.Table.Rows.Item(nIdx).Height = 8;
% end

% Adding headers to table
cColumnHeading = {'Parameter' 'Value'}; % Column Headings
for nIdx = 1:length(cColumnHeading)
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Text = cColumnHeading{nIdx};
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Size = 14;
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginLeft = 0.05;
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginRight = 0.05;
end

%Printing the first 19 Values to the table
for nIdx = 1:(nRow-1)
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Text = xTable.VarName{nIdx,1};
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Size = 11;
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginLeft = 0.05;
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginRight = 0.05;
    
    sCurrVarValue =num2str(xTable.Values(nIdx,1));% Current variable value
    if strcmp(sCurrVarValue,'NaN')
        sCurrVarValue = '-';
    end
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Text = sCurrVarValue;
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Bold = 'msoFalse';
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Size = 11;
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    
end

%Table for the values from 15 to end

hCurrentTable = hCurrentSlide.Shapes.AddTable((numel(xTable.VarName)-(nRow-2)),nColumn,500,80,400,60);% ...
% Adding headers to table
cColumnHeading = {'Parameter' 'Value'}; % Column Headings
for nIdx = 1:length(cColumnHeading)
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Text = cColumnHeading{nIdx};
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Size = 14;
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginLeft = 0.05;
    hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginRight = 0.05;
end

%Printing the first 14 Values to the table
for nIdx = 1:numel(xTable.VarName)-(nRow-1)% general formula for 2nd table
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Text = xTable.VarName{nIdx+nRow-1,1};
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Size = 11;
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginLeft = 0.05;
    hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginRight = 0.05;
    
    sCurrVarValue =num2str(xTable.Values(nIdx+nRow-1,1));% Current variable value
    if strcmp(sCurrVarValue,'NaN')
        sCurrVarValue = '-';
    end
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Text = sCurrVarValue;
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Bold = 'msoFalse';
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Size = 11;
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
    hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
    
end

hCurrentSlide.Shapes.Title.TextFrame.TextRange.Text = 'Summary ';% Slide Title
hCurrentSlide.HeadersFooters.Footer.Text = ['PEMSNOX_Evaluation Summary|TT/S43 TT/XCD|',date];% Adding footer

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pnt_TableCnfg(hCurrentPpt,hSampleSlide,sPathFull)

[sResultPath,~,~] = fileparts(sPathFull); % Getting the folder location
load(sPathFull,'cHdr'); % Loading the Table to be printed
if exist('cHdr')
    nSlide = hCurrentPpt.Slides.Count; % Getting the number of slides in the ppt
    hCurrentSlide = hCurrentPpt.Slides.AddSlide(nSlide+1,hSampleSlide); % Adding new slide
    hCurrentSlide.Select; % Selecting the newly added slide
    
    nRow = length(cHdr); %numel(xTable.VarName)+1; % Num of rows + title row
    nColumn = 2; % Col1 Variable Name Col2 Value
    hCurrentTable = hCurrentSlide.Shapes.AddTable(nRow,nColumn,120,90,700,80);% ...
    %(nRow,nColumn,xcordinate of table start,y of table start
    %width ot the table and height of the table
    %hCurrentTable.Table.Rows.Item(3).Height = 5;% to change height of
    %individual row
    % for nIdx = 1:nRow
    %    hCurrentTable.Table.Rows.Item(nIdx).Height = 8;
    % end
    
    % Adding headers to table
    cColumnHeading = {'Parameter' 'Value'}; % Column Headings
    for nIdx = 1:length(cColumnHeading)
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Text = cColumnHeading{nIdx};
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.TextRange.Font.Size = 14;
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginLeft = 0.05;
        hCurrentTable.Table.Cell(1,nIdx).Shape.TextFrame.MarginRight = 0.05;
    end
    
    %Printing the first 14 Values to the table
    for nIdx = 1:(nRow-1)
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Text = cHdr{nIdx+1,1};
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Bold = 'msoTrue';
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.TextRange.Font.Size = 11;
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginLeft = 0.05;
        hCurrentTable.Table.Cell(nIdx+1,1).Shape.TextFrame.MarginRight = 0.05;
        
        hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Text = cHdr{nIdx+1,2};
        hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Bold = 'msoFalse';
        hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.TextRange.Font.Size = 11;
        hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.HorizontalAnchor = 'msoAnchorCenter';
        hCurrentTable.Table.Cell(nIdx+1,2).Shape.TextFrame.VerticalAnchor = 'msoAnchorMiddle';
        
    end
    
    hCurrentSlide.Shapes.Title.TextFrame.TextRange.Text = 'Configuration Summary ';% Slide Title
    hCurrentSlide.HeadersFooters.Footer.Text = ['PEMSNOX_Evaluation Summary|TT/S43 TT/XCD|',date];% Adding footer
end
end
