function err = disconnect_ue(num_ue, NCellID)

global UE;
global eNodeBS;
global KOL_RB;

NDLRB = KOL_RB;
kol_eb = size(eNodeBS,2);
num_eb = 0;
kol_all_ue = size(UE,2);

% Проверка на подключение мобильного устройства
if (UE{num_ue}.NCellID == 0)
    err = 0;
    return 
end

for i=1:kol_eb
    if (eNodeBS{i}.NCellID == NCellID)
        num_eb = i;
        break;
    end
end

if (num_eb == 0)
    err = 1;
    return
end


buf = size(eNodeBS{num_eb}.UE_RNTI);
xx = buf(2);
num_eb_ue = 0;
RNTI = UE{num_ue}.RNTI;

for i=1:xx
   if (eNodeBS{num_eb}.UE_RNTI(i)   == RNTI)
       num_eb_ue = i;
       break;
   end
end

if (num_eb_ue == 0)
 err = 1;
 return;
end

eNodeBS{num_eb}.UE_RNTI(num_eb_ue) = [];

buf = size(eNodeBS{num_eb}.UE_RNTI);
kol_ue = buf(2);

if (kol_ue == 0)
    k = 0;
    p = 0;
else
    k = fix((NDLRB-2)/kol_ue);
    %p = randperm(NDLRB-2,k*kol_ue);
    p = 1:k*kol_ue;
    p = p + 1;
end
u=1;
p2 = [];
for i=1:kol_ue
    for findd=1:kol_all_ue
        if (UE{findd}.RNTI == eNodeBS{num_eb}.UE_RNTI(i))
            UE{findd}.RB = [];
            break;
        end
    end
    
    p2(i,1) = eNodeBS{num_eb}.UE_RNTI(i);
    for j=1:k
       p(2,u) = eNodeBS{num_eb}.UE_RNTI(i);
       p2(i,j+1) = p(1,u);
       UE{findd}.RB(j) = p(1,u);
       u=u+1;
       
    end
    
end

if (kol_ue == 0)
    k1 = 0;
    p1 = 0;
else
    k1 = fix(((NDLRB*10)-2)/kol_ue);
    %p1 = randperm((NDLRB*10)-2,k1*kol_ue);
    p1 = 1:k1*kol_ue;
    p1 = p1 + 1;
end


u=1;
p3 = [];
for i=1:kol_ue
    p3(i,1) = eNodeBS{num_eb}.UE_RNTI(i);
    for j=1:k1
       p1(2,u) = eNodeBS{num_eb}.UE_RNTI(i);
       p3(i,j+1) = p1(1,u);
       u=u+1;
    end
end

eNodeBS{num_eb}.UE_DL_RB = p3;

UE{num_ue}.NCellID = 0;
UE{num_ue}.freq_band = 0;
UE{num_ue}.maxPower = 0;
UE{num_ue}.RB = [];

eNodeBS{num_eb}.UE_UL_RB = p2;

err = 0;

end