% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function report = GenerateReportAboutBS()

    global eNodeBS;
    global number_UE;

    L = length(eNodeBS);
    report = struct;
    report.name = [];
    report.position = zeros(2, L);
    report.NCellID = zeros(1, L);
    report.freq_band = zeros(1, L);
    report.UE_RNTI = [];
    report.UE_UL_RB = [];
    report.UE_DL_RB = [];
    for i = 1:L 
        report.name = [report.name eNodeBS{i}.name];
        report.position(:, i) = eNodeBS{i}.position;
        report.NCellID(i) = eNodeBS{i}.NCellID;
        report.freq_band(i) = eNodeBS{i}.freq_band;
        UE_RNTI = eNodeBS{i}.UE_RNTI;
        UE_RNTI(number_UE + 1) = 0;
        report.UE_RNTI = [report.UE_RNTI; UE_RNTI];
        UE_UL_RB = eNodeBS{i}.UE_UL_RB;
        UE_UL_RB(:, 10000) = 0;
        report.UE_UL_RB = [report.UE_UL_RB; zeros(1, 10000); UE_UL_RB];
        UE_DL_RB = eNodeBS{i}.UE_DL_RB;
        UE_DL_RB(:, 10000) = 0;
        report.UE_DL_RB = [report.UE_DL_RB; zeros(1, 10000); UE_DL_RB]; 
    end
    
end