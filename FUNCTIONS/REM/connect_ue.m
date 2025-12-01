function err = connect_ue(num_ue, NCellID)

global UE;
global eNodeBS;
global KOL_RB;
NDLRB = KOL_RB;


RNTI = UE{num_ue}.RNTI;

kol_eb = size(eNodeBS,2);
num_eb = 0;
kol_all_ue = size(UE,2);

for i=1:kol_eb
    if (eNodeBS{i}.NCellID == NCellID)
        num_eb = i;
        break;
    end
end

buf = size(eNodeBS{num_eb}.UE_RNTI);
kol_ue = buf(2) + 1;

k = fix((NDLRB-2)/kol_ue);
%p = randperm(NDLRB-2,k*kol_ue);
p = 1:k*kol_ue;
p = p + 1;

eNodeBS{num_eb}.UE_RNTI(kol_ue) = RNTI;

p2 = [];
u=1;
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

k1 = fix(((NDLRB*10)-2)/kol_ue);
%p1 = randperm((NDLRB*10)-2,k1*kol_ue);
p1 = 1:k1*kol_ue;
p1 = p1 + 1;

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

UE{num_ue}.NCellID = NCellID;
UE{num_ue}.freq_band = eNodeBS{num_eb}.freq_band;
UE{num_ue}.maxPower = 23;

eNodeBS{num_eb}.UE_UL_RB = p2;

err = 0;

end