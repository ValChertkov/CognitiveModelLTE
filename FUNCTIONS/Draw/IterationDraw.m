function IterationDraw(draw, Simp_REM)

    %% Нарисовать состояние радиосреды
    if (draw)  
        DrawREM();
        figure(999)
        imagesc(Simp_REM{4, 4})
        drawnow
    end
    
end