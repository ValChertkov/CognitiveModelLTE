function CreateUEsNewSession(draw)

    global UE;
    global number_UE;  
    global number_SU; 
    global samples_in_day;
    global week;
    global stepik; 
    global ref_sesions;
    global noise_p;
    global days_in_year;
    
    %% Новый алгоритм создания расписания связей абонента
    % Формируется длинная кишка данных с шумом
    % Затем она преобразуется в расписание
    for m = 1 : number_UE + number_SU % цикл по всем абонентам
        UE{m}.dataTransfer = []; % сброс на всякий случай
        prepared_X = []; % готовим массив для записей
        for i = 1 : length(week) % по каждому дню в году
            for j = 1 : height(ref_sesions{m}) % по всем шаблонам поведения абонента
                if (week(:, i) == ref_sesions{m}.Combination(j, :)') % если нашли совпадение
                    temp = imnoise(ref_sesions{m}.Base(j, :), 'salt & pepper', noise_p)'; % добавить в поведение шум
                    temp(1 : UE{m}.home_time) = 0; % обнулить внерабочее время
                    temp(UE{m}.work_time : samples_in_day) = 0; % обнулить внерабочее время
                    prepared_X = [prepared_X temp']; % добавить запись в массив
                    break;
                end
            end
        end
        n = 1; % счетчик длины звонка
        if (prepared_X(1) == 1) % если первый элемент 1
        	n = n + 1; % счетчик + 1
        end
        for i = 2 : length(prepared_X) % цикл по оставшимся элементам
            if (prepared_X(i) == 1) % аналогично, если элемент 1
                n = n + 1; % счетчик увеличивается
            end
            if (prepared_X(i) == 0 && prepared_X(i - 1) == 1) % при этом, если звонок завершился
                UE{m}.dataTransfer = [UE{m}.dataTransfer; [i * stepik, n * stepik]]; % записать начало и длительность
                n = 1; % сбросить счетчик
            end
        end   
    end
    
     %% Отрисовка
    if (draw)
        figure(12345)
        d = 100 * 3600 * 24; % перевод кадров LTE в дни
            for i = 1 : number_UE + number_SU
                subplot(number_UE + number_SU, 1, i)
                    stem(UE{1, i}.dataTransfer(:, 1) / d, UE{1, i}.dataTransfer(:, 2) / 1000, 'k.-', 'LineWidth', 1)
                    xlabel('День')
                    ylabel('Длительность сеанса, с')
                    axis([1 days_in_year 0 1.25 * max(UE{1, i}.dataTransfer(:, 2)) / 1000])
                    grid on
            end
    end

end