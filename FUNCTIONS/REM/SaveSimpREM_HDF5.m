% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function [size_f, time_] = SaveSimpREM_HDF5(Simp_REM, time, name_, folder, prognose)

    tic
    
    global REM_gridSize;
    global KOL_RB;
    global out_predict;
    global out_flag_active_SU;
    global week; 
    global accuracy;

    cntRB = ((((KOL_RB+1)*12)*3))*2;
    
    %% ПРЕОБРАЗОВАНИЕ ЯЧЕЕК ДЛЯ ПРЕДСКАЗАНИЯ
    sep = [12 7];                                                        	% размер подматриц 1 несущая и 1/10 кадра
    new_Simp_REM = {};                                                      % новый массив ячеек
    for i = 1:REM_gridSize(1)                                               % для каждой клетки карты
        for j = 1:REM_gridSize(2)                                           % для каждой клетки карты
            temp_REM = Simp_REM{i, j};                                      % берем весь кадр
            new_temp_REM = Gen_Binary_REM(temp_REM);
            new_Simp_REM{i, j} = new_temp_REM;                              % запись данных в ячейку
        end
    end
    Simp_REM = new_Simp_REM;
    
    %% Отрисовка сетки какой-либо ячейки + тестирование прогноза
    % наша модель прогнозирует только для одной ячейки {3, 3} любую линию
    % линий обычно 3 типа: совсем пустые, downlink и uplink
    % я взял фрагменты кода из скрипта, который готовит данные для обучения,
    % т.е. входные данные модели прогноза генерируются аналогично
    if (prognose)
        my_line = 21; % номер какой-нибудь линии из 156 вариантов
        d = 100 * 3600 * 24; % число кадров LTE в сутках
        sample = mod(time, d) / d; % номер отсчета в течение дня 0...1
        line = (my_line - 1) / (156 - 1); % номер линии
        frame_temp = time / d; % для графика номер кадра -> день
        numday = 1 + fix(frame_temp); % номер дня
        pre_KAN = [week(1, numday); week(2, numday); week(3, numday); sample; line]; % входные данные прогноза
        input_KAN = ['python ANN_models/kan/test.py ' num2str(pre_KAN(1)) ',' num2str(pre_KAN(2)) ',' num2str(pre_KAN(3)) ',' num2str(pre_KAN(4)) ',' num2str(pre_KAN(5))];
        output_KAN = PredictKAN(input_KAN); % выходные данные прогноза
        real_REM = Simp_REM{3, 3}(my_line, :); % данные на самом деле
        err = sum(abs(output_KAN - real_REM)) / 20; % вычисление ошибки
        acc = 100 * (1 - err); % вычисление точности
        accuracy = [accuracy acc]; % запись точности в массив
        figure(54321)
            subplot(2, 2, 1)
                imagesc(Simp_REM{3, 3})
                    ylabel('Номер линии RB')
                    xlabel('Номер OFDM-символа')
                    colormap(gray)
            subplot(2, 2, 2) % наша прогнозируемая линия
                plot(1 : 20, real_REM, 1 : 20, -output_KAN, 'LineWidth', 2)
                    xlabel('Слот')
                    ylabel('Состояние')
                    legend('Факт', 'Прогноз')
                    title(['Точность ' num2str(acc) '% для линии ' num2str(my_line)])
                    axis([1 20 -1.25 1.25])
                    grid on
            subplot(2, 2, 3) % наша прогнозируемая линия
                plot(accuracy, 'LineWidth', 2)
                    xlabel('Номер отсчета')
                    ylabel('Точность, %')
                    title(['Средняя точность ' num2str(mean(accuracy)) '%'])
                    grid on
    end
    
    %% СОЗДАНИЕ И ЗАПИСЬ ОСНОВНЫХ ДАННЫХ
    % HDF5
    %     name = ['REM_' name_ '_time_' num2str(time)];
    %     type_file = '.h5';
    %     Simp_REM = uint8([Simp_REM{:}]);
    %     h5create([name '.h5'], '/REM', size(Simp_REM), 'Datatype', 'uint8');
    %     h5write([name '.h5'], '/REM', Simp_REM);
    %     h5writeatt([name '.h5'], '/REM', 'frame', time);
    
    %% СОЗДАНИЕ И ЗАПИСЬ ОСНОВНЫХ ДАННЫХ
    % MAT
    name = [folder 'REM_' name_ '_time_' num2str(time)];
    OUT = struct;
    OUT.Simp_REM = Simp_REM;
    OUT.frame = time;
    % Добавил анализ предстиакания. 0 -все норм, 1 - озночает, что
    % предсказаное значение было не верно. Это только для той базовой
    % станции в которую внедрялись данные SU
    OUT.out_predict = out_predict;
    OUT.active_SU = out_flag_active_SU;
    out_predict = zeros(25,20);
    out_flag_active_SU = 0;
    type_file = '.mat';
    save([name type_file], 'OUT');
    
    %% МЕТАДАННЫЕ (временно отключены, чтобы не замедлять работу)
    %     report_UE = GenerateReportAboutUE();
    %     report_BS = GenerateReportAboutBS();
    %     h5create([name '.h5'], '/BS/name', size(eNodeBS), 'Datatype', 'string');
    %     h5create([name '.h5'], '/BS/position', size(report_BS.position), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/BS/NCellID', size(eNodeBS), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/BS/freq_band', size(eNodeBS), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/BS/UE_RNTI', size(report_BS.UE_RNTI), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/BS/UE_UL_RB', size(report_BS.UE_UL_RB), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/BS/UE_DL_RB', size(report_BS.UE_DL_RB), 'Datatype', 'uint8');
    %     h5write([name '.h5'], '/BS/name', report_BS.name);
    %     h5write([name '.h5'], '/BS/position', report_BS.position);
    %     h5write([name '.h5'], '/BS/NCellID', report_BS.NCellID);
    %     h5write([name '.h5'], '/BS/freq_band', report_BS.freq_band);
    %     h5write([name '.h5'], '/BS/UE_RNTI', report_BS.UE_RNTI);
    %     h5write([name '.h5'], '/BS/UE_UL_RB', report_BS.UE_UL_RB);
    %     h5write([name '.h5'], '/BS/UE_DL_RB', report_BS.UE_DL_RB);
    %     h5create([name '.h5'], '/UE/name', number_UE, 'Datatype', 'string');
    %     h5create([name '.h5'], '/UE/position', [2 number_UE], 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/NCellID', number_UE, 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/freq_band', number_UE, 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/RNTI', number_UE, 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/maxPower', number_UE, 'Datatype', 'single');
    %     h5create([name '.h5'], '/UE/RB', size(report_UE.RB), 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/status', number_UE, 'Datatype', 'uint8');
    %     h5create([name '.h5'], '/UE/base', size(report_UE.base), 'Datatype', 'uint8');
    %     h5write([name '.h5'], '/UE/name', report_UE.name);
    %     h5write([name '.h5'], '/UE/position', report_UE.position);
    %     h5write([name '.h5'], '/UE/NCellID', report_UE.NCellID);
    %     h5write([name '.h5'], '/UE/freq_band', report_UE.freq_band);
    %     h5write([name '.h5'], '/UE/RNTI', report_UE.RNTI);
    %     h5write([name '.h5'], '/UE/maxPower', report_UE.maxPower);
    %     h5write([name '.h5'], '/UE/RB', report_UE.RB);
    %     h5write([name '.h5'], '/UE/status', report_UE.status);
    %     h5write([name '.h5'], '/UE/base', report_UE.base);
    
    %% АРХИВАЦИЯ, ОЧИСТКА, СБОР ДАННЫХ
    zip(name, [name type_file]);
    delete([name type_file]);
    info = dir([name '.zip']);
    size_f = info.bytes / 1024 / 1024;
    
    time_ = toc;

end