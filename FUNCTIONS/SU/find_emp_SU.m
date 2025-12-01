function indx = find_emp_SU(rem, line)
    
    % определение пустого ресурсного блока
    j = 0;
    empy_RB(1,1) = 0;
    empy_RB(1,2) = 0;
    indx(19) = 0;
    xx = (line-1)*12+1:(line-1)*12+12;
    indx(20) = 0;
    for i=0:19

        RR =  rem(xx,i*7+1:(i+1)*7);
        ww = abs(RR(:));
        empy_RE = sum(ww==0);
        if (empy_RE > 70)
            j = j + 1;
            empy_RB(j,1) = i;
            empy_RB(j,2) = empy_RE;
            indx(i+1) = 1;
        end
    end

    
end