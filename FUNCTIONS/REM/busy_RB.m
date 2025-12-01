% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function RB_DL = busy_RB(RB,UEs)

    RB_DL = {[], [], [], [], [], [], [], [], [], []};
    NDLRB = 25;
    kol_ue = size(RB,1);
    xx = size(UEs,2);
    status = false;
    a = 0;
    for i=1:kol_ue
        for find=1:xx
            if (UEs{find}.RNTI == RB(i,1))
                status = UEs{find}.status;
                break;
            end
        end
        if (status == true)

            k1 = size(RB,2);
        else
            k1 = 2;
        end
        for j=2:k1
            pos = fix(RB(i,j)/NDLRB)+1;
            if ((RB(i,j)-((pos-1)*NDLRB)>0) && (RB(i,j)-((pos-1)*NDLRB)<NDLRB))
                RB_DL{pos}(end+1,1) = RB(i,j)-((pos-1)*NDLRB);
            end
        end
    end
    
end