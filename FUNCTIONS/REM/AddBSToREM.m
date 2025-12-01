% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function time_ = AddBSToREM(time) 
    
    global eNodeBS;
    global UE;
    global original;
    global Freq_DL;
    
    tic
    kol_base = size(eNodeBS, 2);
    nuli = int8(zeros(size(original,1),size(original,2)));
    parfor num_base = 1:kol_base
        eNodeBS{num_base}.remSimp = nuli;
        RB = busy_RB(eNodeBS{num_base}.UE_DL_RB, UE);   
        [eNodeBS{num_base}.signal, eNodeBS{num_base}.txgrid, eNodeBS{num_base}.conf] = eNodeB_signal(time, eNodeBS{num_base}.NCellID, RB);
        a = abs(eNodeBS{num_base}.txgrid);
        buf = 2*(a>0.5 & a<=1)+(3*(a>1));
        band = eNodeBS{num_base}.freq_band;
        eNodeBS{num_base}.remSimp(Freq_DL(band, 2):Freq_DL(band, 2) + 299, :) = buf;
    end 
    time_ = toc;
    
end