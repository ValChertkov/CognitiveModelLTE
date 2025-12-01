function schedule = CreateTimeNew(folder, draw)

    global days_in_week;
    global days_in_type;
    global week_in_month;
    global days_in_year;
    global years;

    %% Создание расписания
    schedule = zeros(3, round(years * days_in_year)); % инициализация расписания
    n = 0; % счетчик записей
    for i = 1 : days_in_week : round(years * days_in_year) % проходка по дням
        schedule(1, i : i + 6) = ([1 2 3 4 5 6 7] - 1) / (days_in_week - 1);
        schedule(2, i : i + 6) = ([1 1 1 1 1 2 2] - 1) / (days_in_type - 1);
        schedule(3, i : i + 6) = ([n n n n n n n]) / (week_in_month - 1);
        n = mod(n + 1, week_in_month); % закольцовка номера недель в месяце
    end
    for i = 1 : round(years * days_in_year)
        if (rand() < 0.05) % 5 процентов генерация праздника
            schedule(2, i) = 1;
        end
    end

    %% ОТРИСОВКА
    if (draw)
        figure(777)
            subplot(3, 1, 1)
                stem(1 : round(years * days_in_year), schedule(1, :), 'k.')
                    title('Дни недели')
                    xlabel('День года'); ylabel('Состояния')
                    axis([1 days_in_year 0 1])
            subplot(3, 1, 2)
                stem(1 : round(years * days_in_year), schedule(2, :), 'k.')
                    title('Типы дней')
                    xlabel('День года'); ylabel('Состояния')
                    axis([1 days_in_year 0 1])
            subplot(3, 1, 3)
                stem(1 : round(years * days_in_year), schedule(3, :), 'k.')
                    title('Недели месяца')
                    xlabel('День года'); ylabel('Состояния')
                    axis([1 days_in_year 0 1])
    end
    
    %% СОХРАНЕНИЕ
    save([folder 'week.mat'], 'schedule')

end