function rem = Gen_Binary_REM(simREM)
  
    
    sizeRB = size(simREM);
    rem = int8(zeros(sizeRB(1)/12,sizeRB(2)/7));

    for i = 1:sizeRB(1)/12                                               % для каждого RB в REM 
        for j = 1:sizeRB(2)/7  
         a = 12*(i-1) + 1;
         b = 12*i;
         c = 7*(j-1) + 1;
         d = 7*j;
         tmpREM = simREM(a:b,c:d);
         rem(i,j) = sum(tmpREM > 0, 'all');
        end
    end

    rem = (rem > 6);
end