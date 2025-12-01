% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function [signal,txGrid,rmc_out] = UE_signal(time, ueID, cellID, RB)

    rmc = lteRMCUL('A1-1');
    rmc.NCellID = cellID;
    rmc.RNTI = ueID;
    rmc.NULRB = 25;
    rmc.NFrame = time;
    if (isempty(RB))
      RB = 0;
    end
    rmc.PUSCH.PRBSet = RB';
    [signal, txGrid, rmc_out] = lteRMCULTool(rmc,[1;0;0;1]);
    
end