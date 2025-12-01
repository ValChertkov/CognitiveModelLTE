% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function out = near_base(num_ue)

    global UE;
    global eNodeBS;
    
    out = 0;
    pos_x = UE{num_ue}.position(1);
    pos_y = UE{num_ue}.position(2);
    kol_eb = size(eNodeBS, 2);
    mass = zeros(kol_eb, 1);
    for num_eb = 1:kol_eb
        mass(num_eb) = power(abs(double(pos_x) - eNodeBS{num_eb}.position(1))^2 + abs(double(pos_y) - eNodeBS{num_eb}.position(2))^2, 0.5);
    end
    [mass_min , I] = min(mass);
    if (UE{num_ue}.NCellID ~= eNodeBS{I}.NCellID)
      out = I;
    end
    if (mass_min*250 > 1000) 
      out = -1;
    end
 
end