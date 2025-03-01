function [bStatus,sMessage] = robocopy(sPathSource,sPathTarget,sFile,sFlag)
% ROBOCOPY wrapper file for the robocopy.exe. Make sure the used pathes
% have no blanks in them.
%
% Syntax:
%   [bStatus] = robocopy(sPathSource,sPathTarget,sFile,sFlag)
%   [bStatus,sMessage] = robocopy(sPathSource,sPathTarget,sFile,sFlag)
%
% Inputs:
%   sPathSource - string with source path
%   sPathTarget - string with target path
%         sFile - string file specifier (may contain wildcards *, default: *.*)
%         sFlag - string with flags of robocopy (see robocopy documentation below)
%
% Outputs:
%     bStatus - boolean (1x1) with success state (1: successful copy, 0: failure)
%
% Example: 
%   robocopy(pwd,'c:\temp','test.txt') % copy single file
%   robocopy(sPathSource,sPathTarget,sFile,sFlag)
%
% See also: robocopy.exe, copyfile 
%
% Author: Rainer Frey, TP/PCD, Daimler AG
%  Phone: +49-711-17-34246
% MailTo: rainer.r.frey@daimler.com
%   Date: 2014-08-01

%% robocopy - wrapper function for Microsoft's robocopy.exe to have an
% alternative copyfunction to slow and instable Mathworks copy.
% 
% robocopy.exe Syntax: robocopy Source Destination [File [File]..] 
% 
% Source (Quelle) Specifies the source directory. Source can use the Universal Naming Convention (UNC) format ("\\myserver") or reference a local drive 
% 
% Destination (Ziel) Specifies the destination directory. Destination can use the Universal Naming Convention (UNC) format ("\\myserver") or reference a local drive 
% 
% File Specifies the file or files to copy. Wildcard characters can also be used. *.* is the default value of File. It specifies all files 
% in the directory specified by Source 
% 
% /S Copies all subdirectories, excluding empty ones 
% /E Copies all subdirectories, including empty ones 
% /LEV:n Copies only the top n levels of the source directory tree. n indicates the number of levels 
% /Z Copies files in restartable mode 
% /B Copy files in Backup mode. Copying files in backup mode is not restartable. Backup mode may be able to copy files that restartable mode cannot.... 
% /ZB Use restartable mode; if access is denied, use backup mode 
% /COPY:Copy_Flag The /COPY: parameter copies specified file properties. The default is /COPY:DAT Flag Description
% D File data 
% A File attributes 
% T File time time stamps 
% S File security. This attribute copies the NTFS Access Control Lists (ACL). 
% O File ownership. This attribute copies the NTFS file ownership information. 
% U File auditing. This attribute copies the NTFS file auditing information.
%  
% Note Source and destination volumes must both be NTFS to copy Security, Ownership or Auditing information. 
% /SEC Copy files with security. Equivalent to /COPY:DATS. 
% /COPYALL Copy all file attributes. Equivalent to /COPY:DATSOU. 
% /NOCOPY Does not copy any file attributes.  
% /PURGE Deletes destination files and directories that no longer exist in the source directory.  
% /MIR Mirror a directory tree. The equivalent of /E /PURGE.  
% /MOV Moves files, deleting the source after copying to the destination. 
% /MOVE Moves files and directories, deleting the source after copying to the destination. 
% /A+:{R | A | S | H | N}  Adds the given attributes to copied files. The following table lists the valid attributes: Attribute Description 
% R Read only 
% S System 
% A Archive 
% H Hidden 
% N Not content indexed  
% /CREATE Create directory tree and zero-length files only. 
% /FAT Creates destination files using 8.3 FAT file names only. 
% /FFT Assume FAT File Times (2-second interval). Useful for copying to third-party systems that declare a volume to be NTFS but only implement file times with a 2-second interval. 
% /256 Turn off very long path support. Very long path names are those longer than 256 characters 
% /MON:n Monitors the source for change. The n parameter specifies the number of changes allowed in the source. If this number is exceeded, processing restarts. 
% /MOT:m Monitors the source for change. The m parameter specifies the number of minutes to wait before checking for changes. If there are changes, processing restarts. 
% /RH:hhmm-hhmm Defines the time slot during which starting new copies is allowed. Useful for restricting copies to certain times of the day. Both values must be 24�hour times in the range 0000 to 2359. 
% /PF Makes more frequent checks to see if starting new copies is allowed (per file rather than per pass). Useful in stopping copy activity more promptly at the end of the run hours time slot. 
% /IPG:ms Inter-Packet Gap in milliseconds. This parameter is used to free bandwidth on slow network links 
% /A Copies only files with the archive attribute set. 
% /M Copies only files with the archive attribute set, but removes the archive attribute from source files. 
% /IA:{R | A | S | H | N | C | E} Includes only files with any of the given Attributes set. The following table lists the valid attributes: Attribute Description 
% R Read only 
% A Archive 
% S System 
% H Hidden 
% N Not content indexed 
% C Compressed 
% E Encrypted 
% /XA:{R | A | S | H | N | C | E} Excludes files with any of the given attributes. The following table lists the valid attributes: Attribute Description 
% R Read only 
% A Archive 
% S System 
% H Hidden 
% N Not content indexed 
% C Compressed 
% E Encrypted  
% /XF ExFile Excludes files matching given names, paths, or wildcard characters. 
% /XD Directory Excludes directories matching given names/paths. 
% /XC Excludes changed files. 
% /XN Excludes newer files. 
% /XO Excludes older files. 
% /XX Excludes extra files and directories. 
% /XL Excludes lonely files and directories. 
% /IS Includes same files. 
% /IT Include files tagged as tweaked. 
% /MAX:bytes Excludes files larger than specified. 
% /MIN:bytes Excludes files smaller than specified. 
% /MAXAGE:{days | YYYYMMDD} Excludes files with a Last Modified Date older than n days or specified date. If n is less than 1900, then n is expressed in days. Otherwise, n is a date expressed as YYYYMMDD. 
% /MINAGE:{days | YYYYMMDD} Excludes files with a Last Modified Date newer than n days or specified date. If n is less than 1900, then n is expressed in days. Otherwise, n is a date expressed as YYYYMMDD. 
% /MAXLAD:{days | YYYYMMDD} Excludes files with a Last Access Date older than n days or specified date. If n is less than 1900, then n is expressed in days. Otherwise, n is a date expressed as YYYYMMDD. 
% /MINLAD:{days | YYYYMMDD} Excludes files with a Last Access Date newer than n days or specified date. If n is less than 1900, then n is expressed in days. Otherwise, n is a date expressed as YYYYMMDD. 
% /IOFF Includes Offline files. Excluded by default. 
% /ITEM Includes Temporary files. Excluded by default. 
% /IOFF Includes Offline files. Excluded by default. 
% /XJ Excludes Junction points. 
% /R:RetryNumber Specifies the number of retries on failed copies. The default value of RetryNumber is 1 million. 
% /W:WaitTime Specifies the wait time between retries. The default value for WaitTime is 30 seconds. 
% /REG Saves /R:RetryNumber and /W:WaitTime in the Registry as default settings. 
% /TBD Waits for sharenames to be defined (retry error 67). 
% /L Lists files without copying, time stamping, or deleting any files. 
% /X Reports all extra files, not just those selected. 
% /V Produces verbose output, showing skipped files. 
% /TS Include source file time stamp in the output. 
% /FP Include full path in the output. 
% /NS Excludes the file size from the log file. 
% /NC Excludes the file class from the log file. 
% /NFL Excludes the file names from the log file. 
% /NDL Excludes the directory names from the log file. 
% /NP Suppresses progress display. 
% /ETA Displays estimated time of arrival for copied files. 
% /LOG:file_name Writes status to a log file. If the file exists, it is overwritten. 
% /LOG+:file_name Writes status to a log file. If the file already exists, the status is appended to it. 
% /TEE Displays output in the console window, in addition to directing it to the log file specified by /LOG or /LOG+. 
% /JOB:job_name Gets parameters from the job file. 
% /SAVE:job_name Saves parameters to the job file 
% /QUIT Quits after processing the command line. No files will be copied. Use /QUIT with /JOB to view job file contents. 
% /NOSD Declares that no source directory is specified. Useful in template Jobs for which the source is provided at run time. 
% /NODD Declares that no destination directory is specified. Useful in template Jobs for which the destination is provided at run time. 
% /IF Includes files with the specified names, paths, or wildcard characters. Intended for use in Job files only. 
% /SD:path Explicitly specifies the source directory for the copy. Intended for use in Job files only. 
% /? Displays command-line usage. 

%% init output
bStatus = true;

% input check
if nargin < 3
    sFile = '';
end
if nargin < 4
    sFlag = '';
end
% check for blanks in source/target path
if any(double(sPathSource)==32) || any(double(sPathTarget)==32)
    warning('robocopy:PathWithBlanks','The specified paths contain at least one blank - using MATLAB copyfile...');
    bBlank = true;
else
    bBlank = false;
end

sPathRobocopy = which('robocopy.exe');
if isempty(sPathRobocopy) || bBlank
    if isempty(sFile) % directory copy
        [bStatus,sMessage] = copyfile(sPathSource,sPathTarget);
    else % single file copy
        [bStatus,sMessage] = copyfile(fullfile(sPathSource,sFile),fullfile(sPathTarget,sFile));
    end
    
    % show message on error
    if ~bStatus
        fprintf(2,'Error during "copyfile" use in robocopy.m with message:\n,  %s\n',sMessage);
    end
else
    if isempty(sFile) % directory copy
        [nStatus,sMessage] = system(['"',sPathRobocopy,'" ',sPathSource,' ',sPathTarget,' ',sFlag]);
    else % single file copy
        [nStatus,sMessage] = system(['"',sPathRobocopy,'" ',sPathSource,' ',sPathTarget,' ',sFile,' /COPY:DAT /R:5 /W:10 /LEV:0 ',sFlag]);
    end
    
    % show message on error
    if nStatus > 7
        bStatus = false;
        fprintf(2,'Rocobopy error state: %i\n,  %s\n',nStatus,sMessage);
    end
end
return
