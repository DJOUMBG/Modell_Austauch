% Compare transmission ratio (only forward gears) of TCM and CPC
bCheckTransRatio = 1;
iTrans_TCM = dep.tx_iTxAllFw';
iTrans_CPC = EEP.ptconf_p_Trans.GearRatio_s16(10:25)' * 2^-10;
switch EEP.ptconf_p_Trans.TransType_u8
    case {20, 21} % Voith DIWA differential type 3 or 4
        % Do not check the first gear ratio, since it is not fixed
        iTrans_TCM = iTrans_TCM(2:end);
        iTrans_CPC = iTrans_CPC(2:end);
    case {17, 18, 23, 24, 25, 27} % automatic transmissions from Allison
        % Ignore transmission ratio coming from Allison model
        bCheckTransRatio = 0;
end
if bCheckTransRatio
    if any(abs(iTrans_CPC - iTrans_TCM) > 0.02) % any ratio difference is higher than 0.02
        error('CPC: Please check the configured Transmission! It seems that different transmissions for CPC and TCM are configured!')
    end
end