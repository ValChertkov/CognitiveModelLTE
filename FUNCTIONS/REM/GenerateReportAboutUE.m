% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function report = GenerateReportAboutUE()

    global UE;

    L = length(UE);
    report = struct;
    report.name = [];
    report.position = zeros(2, L);
    report.NCellID = zeros(1, L);
    report.freq_band = zeros(1, L);
    report.RNTI = zeros(1, L);
    report.maxPower = zeros(1, L);
    report.RB = [];
    report.status = zeros(1, L);
    report.base = [];
    for i = 1:L 
        report.name = [report.name UE{i}.name];
        report.position(:, i) = UE{i}.position;
        report.NCellID(i) = UE{i}.NCellID;
        report.freq_band(i) = UE{i}.freq_band;
        report.RNTI(i) = UE{i}.RNTI;
        report.maxPower(i) = UE{i}.maxPower;
        report.status(i) = UE{i}.status;
        RB = UE{i}.RB;
        RB(100) = 0;
        report.RB = [report.RB; RB];
        base = cell2mat(UE{i}.base);
        base(25) = 0;
        report.base = [report.base; base];
    end
    
end