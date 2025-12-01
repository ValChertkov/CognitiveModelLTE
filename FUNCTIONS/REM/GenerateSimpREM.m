% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function [Full_REM, time_] = GenerateSimpREM(draw, time)

    global REM_gridSize;
    global eNodeBS;
    global UE;
    global KOL_RB;

    cntRB = ((((KOL_RB+1)*12)*3))*2;
    tic
    Full_REM{REM_gridSize(1), REM_gridSize(2)} = []; 
    kol = REM_gridSize(1) * REM_gridSize(2);
    
    % У  МЕНЯ PARFOR тут не работает / Чертков В.М.
    %parfor i = 1:kol
    for i = 1:kol
        x = fix((i - 1) / REM_gridSize(1)) + 1;
        y = mod((i - 1), REM_gridSize(2)) + 1;
        Full_REM{i} = REM_gen(x, y, eNodeBS, time);  
    end 
    
    if (draw == true)
        p = zeros(REM_gridSize(1), REM_gridSize(2));
        for i = 1:size(Full_REM, 1)
            for j = 1:size(Full_REM, 2)
                temp = Full_REM{i, j};
                temp = max(temp');
                temp = find(temp == 0);
                p(i, j) = length(temp) / cntRB;
            end
        end
        figure(99)
            imagesc(p')
            colormap(gray)
            drawnow
    end
    time_ = toc;
    
end