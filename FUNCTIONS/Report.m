% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function Report(time, tStart)

    global all_time;

    persent = (time / all_time) * 100;
    ost = 100 - persent;
    disp('====')
    disp(['Текущий день: ' num2str(time / 100 / 3600 / 24)])
    disp(['Моделирование: ' num2str(persent) '% | ' num2str(uint64(toc(tStart))) ' сек | ' num2str(time) ' кадр.'])
    disp(['Прогноз оставшегося времени: ~' num2str(ost * toc(tStart) / persent / 3600) ' ч'])
    disp('====')
    disp(' ')
    
end