function [nChange,nStatus] = p4copy(cSource,sDescription,cPathPart)
% P4COPY integrated wrapper for "p4 copy" operations to cover handling
% modifiers and automatic reverse switch for release streams.
%
% Syntax:
%   [nChange,nStatus] = p4copy(cSource,cPathPart)
%
% Inputs:
%     cSource - string or cell of strings with source stream in depot notation
%               e.g. //DIVe/dbm_platform or file system notation, 
%               if development stream -> copy operation to parent, 
%               if release stream -> copy operation from parent (-r reverse flag)
%   sDescription - string with additional part of changelist description
%   cPathPart - string or cell of strings with partial path in stream for integration filter 
%               e.g. com/DIVe/Function or com\DIVe\Function
%
% Outputs:
%   nChange - integer (1x1) with changelist number of copy operation
%   nStatus - integer (1x1) with status of operation
%               0: success on p4 copy
%               1: fail in process
%
% Example: 
%   [nChange,nStatus] = p4copy('//DIVe/dam_platform')
%   [nChange,nStatus] = p4copy('//DIVe/dam_platform','some improvements')
%   cPathPart = {'com/DIVe/Function','com/DIVe/Utilities','int/DIVe/Function','int/DIVe/Utilities'}
%   [nChange,nStatus] = p4copy(cSource,'some improvements',cPathPart)
%
% See also: p4, p4change
%
% Author: Rainer Frey, TP/EAC, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2020-02-10

% initialize output
nChange = [];
nStatus = 0;

% check input
if nargin < 1 || isempty(cSource)
    cSource = '...';
end
if ischar(cSource)
    cSource = {cSource};
end
if nargin < 2
    sDescription = '';
end

% get stream information
cStream = hlxOutParse(p4('streams'),' ',4,true);

% basic check on source
if numel(cSource{1}) < 2
    error('p4copy:insufficentSource','Specified source stream is not valid: %s',cSource{1});
end

% determine workspace in case of passed path or file
if exist(cSource{1},'dir') || exist(cSource{1},'file')
    % fix missing path of files in current MATLAB path (file only input)
    if isempty(fileparts(cSource{1}))
        cSource{1} = which(cSource{1});
    end
    
    % get clients including stream information and root folder
    xClient = hlxZtagParse(p4('-z tag','clients','--me',...
        sprintf('-E *%s*',upper(getenvOwn('computername')))));
    % cClient = hlxOutParse(p4('clients','--me'),' ',5,true);
    cDummy = repmat({'Dummy'},numel(xClient),1);
    cClient = [cDummy {xClient.client}' cDummy cDummy {xClient.Root}'];
    
    % determine workspace of file or folder
    cRoot = cellfun(@(x)['^' regexptranslate('escape',[x,filesep])],{xClient.Root},'UniformOutput',false);
    bClient = ~cellfun(@isempty,regexpi([cSource{1},filesep],cRoot,'once','start'));

    if sum(bClient) > 1
        % error on multiple matches
        nStatus = 1;
        fprintf(2,['The specified file/folder '...
              '"%s" is part of multiple p4 clients: \n' ...
              repmat('%s\n',1,sum(bClient))],cSource{1},cClient{bClient,2});
        return
    elseif sum(bClient) == 1
        % exact one workspace matches
        cSource{1} = cClient{bClient,2};
    else
        % file/folder is not in workspace
        nStatus = 1;
        fprintf(2,['The specified file/folder "%s" is not in a p4 '...
                   'workspace of this client.\n'],cSource{1});
        return
    end
    
    % assign stream
    sStream = xClient(bClient).Stream;
    % determine partial paths to subsequent folders/files (relative to root)
    bRootSame = cellfun(@(x)strcmpi(xClient(bClient).Root,x(1:numel(xClient(bClient).Root))),cSource);
    cSource = cSource(bRootSame);
    if any(~bRootSame)
        cOther = cSource(~bRootSame);
        fprintf(2,['p4copy: consistent streams/sources on cell stream input needed.\n' ...
            'Omitted following entries:\n']);
        for nIdxOther = 1:numel(cOther)
            fprintf(2,'%s\n',cOther{nIdxOther});
        end
    end
    cPathPart = cellfun(@(x)x(numel(xClient(bClient).Root)+2:end),cSource,'UniformOutput',false);
    
elseif strcmp(cSource{1}(1:2),'//') % passed Perforce Helix depot notation
    
    % determine stream
    sStream = regexp(cSource{1},'//\w+/\w+','match','once');
    if isempty(sStream)
        error('p4copy:incompleteDepotPath','p4copy - incomplete depot path on source: %s',cSource{1});
    end
    
    % on cell input of streams
    if numel(cSource) > 1
        % check consistent entry of streams in cell
        bStreamSame = cellfun(@(x)strcmp(sStream,x(1:min(numel(x),numel(sStream)),cStrem)),cStream);
        if any(~bStreamSame)
            fprintf(2,['p4copy: consistent streams on cell stream input needed.\n' ...
                'Omitted following entries:\n']);
            for nIdxMiss = find(~bStreamSame')
                fprintf(2,'%s\n',cStream{nIdxMiss});
            end
        end % if any non consistent
        
        % derive path parts of subsequent filters
        cPathPart = cellfun(@(x)x(numel(sStream)+2:end),cStream,'UniformOutput',false);
        bEmpty = cellfun(@isempty,cPathPart);
        cPathPart = cPathPart(~bEmpty);
    end % if source cell vector
end % if is file/folder
bStream = strcmp(sStream,cStream(:,2));

% get next non-virtual stream
[bReal,sReal,sType,sParent] = getStreamNonVirtualParent(bStream,cStream); %#ok<ASGLU>

% switch to a target workspace
p4switch([sParent '/...']);

% create changelist
switch sType
    case 'release'
        sSource = sParent;
        sDestination = sStream;
        p4switch(sStream,false);
    case 'development'
        sSource = sStream;
        sDestination = sParent;
        p4switch(sParent,false);
end

sDestinationSingle = regexp(sDestination,'\w+$','match','once');
sDescription = sprintf('Copying %s to %s (%s) - %s',...
    sSource,sDestinationSingle,sDestination,sDescription);
nChange = p4change(sDescription);

% issue copy command
for nIdxSource = 1:numel(cPathPart)
    cFolder = pathparts(cPathPart{nIdxSource});
    
    switch sType
        case 'release'
            sFileSource = strGlue([{sParent},cFolder{:},'...'],'/');
            sMsg = p4(sprintf('copy -F -c %i -S %s -r -s %s',nChange,sReal,sFileSource)); %#ok<NASGU>
        case 'development'
            sFileSource = strGlue([{sStream},cFolder{:},'...'],'/');
            sMsg = p4(sprintf('copy -c %i -S %s -s %s',nChange,sReal,sFileSource)); %#ok<NASGU>
    end
end

% cleanup
xChange = hlxDescribeParse(nChange);
if isempty(xChange.cFile)
    p4(sprintf('change -d %i',nChange));
    fprintf(1,'No files to submit with p4copy - delete empty changelist %i\n',nChange);
    return
end

% submit copy change
p4(sprintf('submit -c %i',nChange));
fprintf(1,'Submitted p4copy to Helix in change %i: "%s"\n',nChange,sDescription);
return

% =========================================================================

function [bReal,sReal,sType,sParent] = getStreamNonVirtualParent(bStream,cStream)
% GETSTREAMNONVIRTUALPARENT get the next non-virtual parent stream of the
% specified stream index in a p4 streams output-
%
% Syntax:
%   bStreamNew = getStreamNonVirtualParent(bStream,cStream)
%
% Inputs:
%   bStream - boolean (mx1) to indicate specified stream
%   cStream - cell (mx4) with strings of parsed streams in Helix
%              cStream = hlxOutParse(p4('streams'),' ',4,true)
%             (:,1) - string "Stream"
%             (:,2) - string with //<depot>/<stream>
%             (:,3) - string with type of stream
%             (:,4) - string with parent of stream as //<depot>/<stream> or
%                     "none" for mainline streams (they have no parent)
%
% Outputs:
%   bReal - boolean (1xm) with index of next real parent stream
%   sReal - string with next real parent stream in depot notation
%
% Example: 
%   bStreamNew = getStreamNonVirtualParent(bStream,cStream)

% check input
if ~any(bStream)
    error('p4copy:getStreamNonVirtualParent:StreamIndexNotValid',...
        'p4copy:getStreamNonVirtualParent - empty stream index at input.');
elseif sum(bStream) > 2
    error('p4copy:getStreamNonVirtualParent:StreamIndexMultiple',...
        'p4copy:getStreamNonVirtualParent - multiple stream index at input.');
end
if isempty(cStream)
    error('p4copy:getStreamNonVirtualParent:StreamCellEmpty',...
        'p4copy:getStreamNonVirtualParent - empty stream list at input.');
end

% loop to next nonvirtual stream
bReal = bStream;
while strcmp(cStream(bReal,3),'virtual')
    bReal = strcmp(cStream(bReal,4),cStream(:,2));
    if ~any(bReal)
        error('p4copy:getStreamNonVirtualParent:StreamIndexNotValid',...
            'p4copy:getStreamNonVirtualParent - empty stream index at loop.');
    elseif sum(bReal) > 2
        error('p4copy:getStreamNonVirtualParent:StreamIndexMultiple',...
            'p4copy:getStreamNonVirtualParent - multiple stream index at loop.');
    end
end

% get output parameters
sReal = cStream{bReal,2};
sType = cStream{bReal,3};
sParent = cStream{bReal,4};
return
