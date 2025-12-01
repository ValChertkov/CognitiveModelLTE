function out = suImport(rem, indx)
    global PercenDataSU
    uk = 1;
    for uk = 1:25
        if (sum(indx(uk,:)) > 0)
            kol = fix(sum(indx(uk,:))*PercenDataSU/100);
            emp = randperm(kol,kol);
            j=1;
            ggg(1)=0;
            for i=1:20
               if (indx(uk,i) > 0)
                ggg(j) = i; 
                j = j + 1;    
               end
            end
            emp = randperm(j-1,kol);
            xx = (uk-1)*12+1:(uk-1)*12+12;
            for j=1:kol 
                M = 16;
                %k = log2(M);
                data = randi([0 1],12*7*4,1);
                
                b1 = hex2poly('5f9e3985','ascending'); %SU1 UUID
                b2 = hex2poly('342fd71c','ascending'); %SU2 UUID
                
                b3(32) = 0;
                b3(1:size(b1,2)) = b1(1:size(b1,2));
                
                b4(32) = 0;
                b4(1:size(b2,2)) = b2(1:size(b2,2));
                
                txSig(1:32) = b3(1:32);
                txSig(33:64) = b4(1:32);
                
                txSig = qammod(data,M,'InputType','bit','UnitAveragePower',true);
                %scatterplot(txSig);
                
                SU = reshape(txSig,[12,7]);
                a = abs(SU);
                buf = 2 * (a > 0.5 & a <= 1) + (3 * (a > 1));
                %importSU
                i = 0;
                i = ggg(emp(j))-1;
            
                %figure;
                %imagesc(abs(rem));
                rem(xx,i*7+1:(i+1)*7) = buf(1:12,1:7);
                %figure;
                %imagesc(abs(rem));
            end
        end
    end
    out = rem;


end