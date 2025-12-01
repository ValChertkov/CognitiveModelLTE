function data_all = SessionsVariance(draw)

    global days_in_week;
    global days_in_type;
    global week_in_month;
    global samples_in_day;
    global number_UE;
    global number_SU;

    %% ГЕНЕРАЦИЯ СЕССИЙ
    emitions = [0.5 0.5; 0.5 0.5]; % настройки цепи Маркова
    data_all = {}; % инициализация массива
    for l = 1 : number_UE + number_SU % цикл по всем абонентам
        n = 1; % счетчик
        data = table; % промежуточная табличка
        for i = 1 : days_in_week % дни недели
            for j = 1 : days_in_type % типы дней
                for k = 1 : week_in_month % недели месяца
                    data.Combination(n, :) = [(i - 1) / (days_in_week - 1) (j - 1) / (days_in_type - 1) (k - 1) / (week_in_month - 1)]; % входные данные
                    state_1 = 0.85 + (0.1 * rand()); % состояние не-звонка
                    state_2 = 1 - state_1; % состояние звонка
                    transitions = [state_1 state_2
                                   state_2 state_1]; % переходы между состояниями
                    [~, state] = hmmgenerate(samples_in_day, transitions, emitions); % генерация переходов
                    state(end) = 1; % любой день завершается без звонка
                    data.Base(n, :) = state - 1; % нормировка данных
                    n = n + 1; % счетчик записей + 1
                end
            end
        end
        data_all{l} = data;
    end

    %% РИСОВКА
    if (draw)
        figure(666)
            k = 5; m = 1; n = 1;
            for j = 1 : m
                for i = 1 : k
                    subplot(k, m, n)
                        plot(data_all{j}.Base(i, :), 'k-.', 'LineWidth', 1)
                            title((num2str(data_all{j}.Combination(i, :))))
                            axis([1 samples_in_day 0 1.25])
                    n = n + 1;     
                end
                xlabel('Номер отсчета')
            end
    end
    
end