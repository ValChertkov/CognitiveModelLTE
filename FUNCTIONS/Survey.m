% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function Survey(time, time_1, time_2, time_3, time_4, time_5, time_6, time_7, size_f)

    disp(['Кадр №' num2str(time)])
    disp(['Действия UE:        ' num2str(time_1 + time_2 + time_3) ' сек'])
    disp(['Ресурсная сетка:    ' num2str(time_4 + time_5) ' сек'])
    disp(['Генерация REM:      ' num2str(time_6) ' сек'])
    disp(['Сохранение в HDF5:  ' num2str(size_f) ' МБ / ' num2str(time_7) ' сек'])
    disp(['Всего:              ' num2str(time_1 + time_2 + time_3 + time_4 + time_5 + time_6 + time_7) ' сек'])
    disp(' ')
    
end