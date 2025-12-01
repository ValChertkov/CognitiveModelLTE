% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function [Freq_band, original] = CaclFreqBands(down, up, step)

    global KOL_RB;

    low = down;                             
    high = up;                              
    Freq_band = int32(zeros(1, ((((KOL_RB+1)*12)*3))*2));      
    j = 1;                                  
    for i = low:step:low + ((((KOL_RB+1)*12)*3)*15)  -1       
        Freq_band(j) = i;                   
        j = j + 1;                          
    end
    for i = high:step:high + ((((KOL_RB+1)*12)*3)*15)  -1     
        Freq_band(j) = i;                   
        j = j + 1;                          
    end
    original(j - 1, 140) = 0;             
    original = single(complex(original));
    
end