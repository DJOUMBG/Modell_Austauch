% Check of availability of Silversim.exe file
fprintf(2, 'silversim.exe only available with full Silver version, not in Silver runtime environment\n');
fprintf(2, 'Todo: I need to compile the CAL module into S-Function and not DLL\n');
[status, ~] = dos('silversim --version');
if status
    CAL.cal_m_EnCal_u8 = 1;
    fprintf(2, 'Shift parameter cannot be changed, you have to live with the original parameter from the CDS file :-)\n');
    return
end

% Create vehicle configuration for CAL input
createInit(EEP, INIT_FILE) 

% Run CAL Module for 5s with Silver
[status, cmdout] = dos('silversim -c -E 5 CAL.sil'); % run Silver
if status
    disp(cmdout)
    error('Silver did not work with CAL Module of the CPC')
end