function CreateUEsNewMove(draw)

    global UE;
    global number_UE;  
    global samples_in_day;
    global week;
    global days_in_type;
    global stepik; 
    global REM_gridSize;
    global days_in_year;
    
    %% Новый алгоритм создания расписания перемещения абонента
    % Все абоненты работают по графику 5/2, у них есть рабочее и домашнее место
    % В рабочие дни они отправляются на работу, в выходные и праздники сидят дома
    for i = 1 : number_UE
        home_point = RandomCoords();
        work_point = RandomCoords();
        UE{i} = CreateUE(i, home_point, 0, i, 23, 'PU');
        UE{i}.home_time = randi([1 round(0.3 * samples_in_day)]);
        UE{i}.work_time = UE{i}.home_time + randi([round(0.4 * samples_in_day) round(0.4 * samples_in_day)]);
        UE{i}.trajectory = [0 home_point];
        for j = 1 : length(week)
            % только в рабочий день есть перемещения
            if (week(2, j) == 0) % ищем рабочий день
                offset_time = (j - 1) * stepik * samples_in_day;
                UE{i}.trajectory = [UE{i}.trajectory; [offset_time + UE{i}.home_time * stepik, home_point]];
                UE{i}.trajectory = [UE{i}.trajectory; [offset_time + UE{i}.work_time * stepik, work_point]];
            end
        end
    end
    
    if (draw)
        figure(123456)
            d = 100 * 3600 * 24; % перевод кадров LTE в дни
            for i = 1 : number_UE
                subplot(number_UE, 1, i)
                    plot(UE{1, i}.trajectory(:, 1) / d, UE{1, i}.trajectory(:, 2), 'r.', UE{1, 1}.trajectory(:, 1) / d, UE{1, i}.trajectory(:, 3), 'b.', 'LineWidth', 1)
                    xlabel('Абсолютное время модели, день')
                    ylabel('Координаты X и Y')
                    axis([0 (days_in_year * samples_in_day * stepik / d) -1 REM_gridSize(1) + 1])
                    grid on
            end
    end

end