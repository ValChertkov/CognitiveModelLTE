% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function UE = CreateUE(number, position, band, RNTI, maxPower, type)

    UE = struct;
    UE.name = "Abonent #" + num2str(number);
    UE.position = position;
    UE.NCellID = 0;
    UE.freq_band = band; 
    UE.RNTI = RNTI;
    UE.maxPower = maxPower;
    UE.RB = [];
    UE.status = false;
    UE.trajectory = {};
    UE.base = {};
    UE.dataTransfer = [];
    UE.move_type = '';
    UE.work_days = [];
    UE.home_time = 0;
    UE.work_time = 0;
    UE.type = type; % PU или SU
    
end