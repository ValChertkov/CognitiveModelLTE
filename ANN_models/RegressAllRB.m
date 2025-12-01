clear all; close all; clc;
disp([datestr(datetime) ' Программа запущена'])

%% 0. Настройки
path = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\results_test2\';
path_week = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\week_test2\';
path_temp = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\temp\';
path_model = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\model2\';
path_out = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\out2\';
REM_size = 7 * 7;    	% общее количество ячеек
SubCarrier = 5;         % номер интересующей нас линии (в модели их около 160)
CellGoal = [3 3];       % номер интересующей ячейки (например, по центру)
days_in_year = 336;     % дней в году (не 365, потому что у нас в каждом месяце ровно по 4 недели)
samples_in_day = 100;	% отсчетов за день
train_test = 0.8;       % разделение данных
train_val = 0.2;        % разделение данных
interval = 100 * (86400 / samples_in_day); % шаг модели (производное от отсчетов в день)
Carr_L = 156; % число линий (должно быть 166)
d = 100 * 3600 * 24; % число кадров LTE в сутках

%% 1. Загрузка данных
% файлы распаковываются и заносятся в табличку
% чтение файла, статусов и кадров
directory = dir(path); % папка с файлами
numFiles = length(directory); % количество файлов
data = struct; % инициализация структуры
data(numFiles - 2, Carr_L).status = zeros(1, 10); % инициализация полей под размер
data(numFiles - 2, Carr_L).frame = []; % инициализация полей под размер
data(numFiles - 2, Carr_L).line = []; % инициализация полей под размер
cx = CellGoal(1); cy = CellGoal(2); % предвычисление координат (ради оптимизации)
parfor i = 3 : numFiles % параллельный цикл по файлам с 3 (1 и 2 - это системное что-то там)
    file = unzip([path directory(i).name], path_temp); % распаковка данных      
    for j = 1 : Carr_L % цикл по линиям
        data(i - 2, j).status = single(load(file{1}).OUT.Simp_REM{cx, cy}(j, :)); % в статус идет состояние слотов
    	data(i - 2, j).frame = single(load(file{1}).OUT.frame); % в кадр идет его номер (кадра LTE от начала)
        data(i - 2, j).line = (single(j) - 1) / (Carr_L - 1); % помечается номер линии
    end
    if (mod(i, 1000) == 0)
    	disp([datestr(datetime) ' Распаковано ' num2str(uint16(i / 1000)) '/' num2str(uint16(numFiles / 1000)) ' пакетов' ])
    end
end
disp([datestr(datetime) ' Файлы распакованы'])

%% 2. Проверка данных + график
% кадры в номер отсчета в день
full_data(numFiles - 2, Carr_L).status = []; % инициализация полей под размер
full_data(numFiles - 2, Carr_L).frame = []; % инициализация полей под размер
full_data(numFiles - 2, Carr_L).line = []; % инициализация полей под размер
full_data(numFiles - 2, Carr_L).sample = []; % инициализация полей под размер
full_data(numFiles - 2, Carr_L).numday = []; % инициализация полей под размер
for j = 1 : Carr_L % цикл по линиям
    data_line = data(:, j); % копируется отдельная линия
    frames = zeros(1, length(data_line)); % отдельный массив номеров кадров для отрисовки по дням недели
    statuses = zeros(1, length(data_line)); % отдельный массив статусов для отрисовки
    [~, order] = sort([data_line.frame], 'ascend'); % отсортировать линию по номерам кадров
    data_line = data_line(order); % применение сортировки
    for i = 1 : length(data_line) % проходка по одной линии
        data_line(i).sample = mod(data_line(i).frame, d) / d; % номер отсчета в течение дня 0...1
        frames(i) = data_line(i).frame / d; % для графика номер кадра -> день
        data_line(i).numday = 1 + fix(frames(i)); % номер дня
        statuses(i) = mean(data_line(i).status); % для графика статус кадра как среднее его слотов
    end
    full_data(:, j) = data_line; % расширенная запись линии в массив
    
    if (j <= 10) % отрисовка первых 3 недель для первых 10 линий (для проверки)
        figure(1)
            subplot(10, 1, j)
                stem(frames, statuses, 'k.')
                    title(['Линия ' num2str(j)])
                    axis([1 100 -0.25 1.25])
                    xlabel('Номер дня')
                    ylabel('Статус')
                    grid on
                    drawnow
    end
end
clear statuses; clear frames; clear order;
disp([datestr(datetime) ' Файлы первично обработаны'])

%% 3. Подготовка данных
% дозапись пропущенных данных
week = load([path_week 'week.mat']).schedule; % загрузка расписания
wait_line = samples_in_day * days_in_year; % ожидаемая длина данных по одной линии
wait_size = Carr_L * wait_line; % ожидаемый общий размер данных
prepared_X = []; % инициализация массива входных данных
prepared_Y = []; % инициализация массива входных данных
for j = 1 : Carr_L % цикл по линиям
    data_line = full_data(:, j); % копирование отдельной линии
    prepared_X_line = single(zeros(wait_line, 5));
    prepared_Y_line = single(zeros(wait_line, 20));
    m = 1;
    for i = 1 : length(data_line) - 1 % проход по взятой линии
        num_day = data_line(i).numday; % номер дня
        samp = data_line(i).sample; % номер отсчета в рамках одного дня
        now_frame = data_line(i).frame; % абсолютный номер отсчета
        next_frame = data_line(i + 1).frame; % абсолютный номер следующего отсчета
        delta = (next_frame - now_frame) / interval;
        if (mod(delta, 1) ~= 0)
            delta = round(delta);
        end
        for k = 1 : delta
            prepared_Y_line(m + k - 1, :) = data_line(i).status;
        end
        prepared_X_line(i, :) = [week(1, num_day); % день недели
                                 week(2, num_day); % тип дня
                                 week(3, num_day); % номер недели в месяце
                                 data_line(i).sample; % номер отсчета дня
                                 data_line(i).line]; % номер линии      
        m = m + delta;
    end
            
    frames = (0 : wait_line - 1) / 100; % для графиков
    if (j <= 5) % отрисовка первых 3 недель для первых 10 линий (для проверки)
        
%         % тест взаимной корреляции
        if (j == 4)
            for_test = mean(prepared_Y_line');
            c = fft(for_test);
            c = c .* conj(c);
            c = real(ifft(c));
            c = c / max(c);
            tc = frames;
            figure(999)
            plot(tc, c)
%             break;
        end
         
        figure(2)
            subplot(5, 1, j)
%                 plot(frames, prepared_Y_line, 'k.', frames, prepared_X_line(:, 1), 'r', frames, prepared_X_line(:, 2), 'b', frames, prepared_X_line(:, 3), 'g')
                plot(frames, prepared_Y_line, 'k', frames, prepared_X_line(:, 4), 'r')
                    title(['Линия ' num2str(j)])
                    axis([1 336 -0.5 1.5])
                    xlabel('Номер дня')
                    ylabel('Статус')
                    grid on
                    drawnow
    end
    
    prepared_Y = [prepared_Y; prepared_Y_line];
    prepared_X = [prepared_X; prepared_X_line];
    disp(['Линия ' num2str(j)])
end
% clear prepared_X_line; clear prepared_Y_line; clear frames; clear data_line;
disp([datestr(datetime) ' Файлы заполнены'])

%% 4. Перемешивание данных
% в данных где-то густо, а где-то пусто, и если их не перемешать, то выйдет ерунда
a = 1 : length(prepared_X); % исходный порядок
b = a(randperm(length(a))); % перемешанный порядок
prepared_X_rand = prepared_X; % копирование массива входных данных
prepared_Y_rand = prepared_Y; % копирование массива выходных данных
parfor i = 1 : length(prepared_X)
    prepared_X_rand(i, :) = prepared_X(b(i), :);
    prepared_Y_rand(i, :) = prepared_Y(b(i), :);
end

% графики
len_plot = 1000;
figure(3)
    subplot(6, 1, 1)
        plot(mean(prepared_Y_rand'))
            axis([1 len_plot 0 1.25])
            grid on
    for i = 1 : 5
        subplot(6, 1, i + 1)
            plot(prepared_X_rand(:, i))
                axis([1 len_plot 0 1.25])
                grid on
    end
    
clear prepared_X; clear prepared_Y; clear len_plot; clear a; clear b;
disp([datestr(datetime) ' Данные перемешаны'])
        
%% 5. Разделение данных
train_test_size = round(train_test * length(prepared_X_rand));
X_train = single(prepared_X_rand(1 : train_test_size, :));
Y_train = single(prepared_Y_rand(1 : train_test_size, :));
X_test = single(prepared_X_rand(train_test_size + 1 : end, :));
Y_test = single(prepared_Y_rand(train_test_size + 1 : end, :));
clear prepared_X_rand; clear prepared_Y_rand;
disp([datestr(datetime) ' Данные подготовлены'])

%% Эксперимент
Y_train_ex = mean(Y_train');
Y_test_ex = mean(Y_test');

%% 6 Сохранение
mkdir(path_out); % пересоздание каталога
save([path_out 'X_test.mat'], 'X_test');
save([path_out 'Y_test.mat'], 'Y_test_ex');
save([path_out 'X_train.mat'], 'X_train');
save([path_out 'Y_train.mat'], 'Y_train_ex');
disp([datestr(datetime) ' Данные сохранены'])
        
%% 7. Обучение
% 1 слой по 100: 585 ит. 0.16 (порог 0.5)
% 2 слоя по 50: 469 ит. 0.12 (порог 0.5)
% 4 слоя по 25: 1000 ит. 0.1 (порог 0.5)
% 5 слоев по 20: 444 ит. 0.099 (порог 0.5)
% 10 слоев по 10: 252 ит. 0.13 (порог 0.5)
% 10 слоев по 20: 332 ит. 0.087 (порог 0.6)
% 5 cлоев 20 10 5 10 20: 266 ит. 0.15
% 3 cлоя 100 100 100: 
% net = fitnet(1000);
net = newff(X_train', Y_train_ex, [20 10]);
net = configure(net, X_train', Y_train_ex);
view(net) 
net.divideParam.trainRatio = 0.8;
net.divideParam.valRatio = 0.1;
net.divideParam.testRatio = 0.1;
net = train(net, X_train', Y_train_ex, 'useParallel', 'yes', 'showResources', 'yes');
    
%% 8. Прогноз
mass_err = []; mass_err_0 = []; mass_err_1 = [];
len = 0.05 : 0.05 : 0.95; 
for j = len
%     y = mean(net(X_test'));
    y = net(X_test');
    err = 0; 
    err_1 = 0; err_1_len = 0;
    err_0 = 0; err_0_len = 0;
    for i = 1:length(y)
        if (y(i) < j)
            y(i) = 0;
        else
            y(i) = 1;
        end
        if (y(i) ~= Y_test_ex(i))
            err = err + 1;
        end
        if (Y_test_ex(i) == 1)
            err_1_len = err_1_len + 1;
            if (y(i) ~= Y_test_ex(i))
                err_1 = err_1 + 1;
            end
        end
        if (Y_test_ex(i) == 0)
            err_0_len = err_0_len + 1;
            if (y(i) ~= Y_test_ex(i))
                err_0 = err_0 + 1;
            end
        end
    end
    err = ((err / length(y)));
    err_1 = ((err_1 / err_1_len));
    err_0 = ((err_0 / err_0_len));
    mass_err = [mass_err err];
    mass_err_0 = [mass_err_0 err_0];
    mass_err_1 = [mass_err_1 err_1];
end
min_err = min(mass_err);
  
figure(6)
    plot(len, mass_err, 'k-', len, mass_err_0, 'r:', len, mass_err_1, 'b-.', 'LineWidth', 1.5)
    legend('Общая ошибка', 'Ошибка 1-го рода', 'Ошибка 2-го рода')
    xlabel('Порог бинаризации')
    ylabel('Уровень ошибки')
    axis([0.05 0.95 0 max([max(mass_err) max(mass_err_0) max(mass_err_1)])])
    grid on
    
%% ОКОНЧАТЕЛЬНО
y = mean(net(X_test'));
z = y;
err = 0;
err_1 = 0; err_1_len = 0;
err_0 = 0; err_0_len = 0;
for i = 1:length(y)
    if (y(i) < 0.4)
        y(i) = 0;
    else
        y(i) = 1;
    end
    if (y(i) ~= Y_test(i))
        err = err + 1;
    end
    if (Y_test(i) == 1)
        err_1_len = err_1_len + 1;
        if (y(i) ~= Y_test(i))
            err_1 = err_1 + 1;
        end
    end
    if (Y_test(i) == 0)
        err_0_len = err_0_len + 1;
        if (y(i) ~= Y_test(i))
            err_0 = err_0 + 1;
        end
    end
end
err = 1 - ((err / length(y)));
err_1 = 1 - ((err_1 / err_1_len));
err_0 = 1 - ((err_0 / err_0_len));

len = length(y);
figure(7)
    subplot(3, 1, 1)
        plot(1:len, Y_test(1:len))
%             axis([4500 7500 0 1.1])
            title('Реальные данные')
            ylabel('Состояние')
    subplot(3, 1, 2)
        plot(1:len, y)
            title('Бинаризованный прогноз')
%             axis([4500 7500 0 1.1])
            ylabel('Состояние')
    subplot(3, 1, 3)
        plot(1:len, z)
            title('Прогноз')
%             axis([4500 7500 0 1.1])
            xlabel('Номер отсчета')
            ylabel('Состояние')

%% СОХРАНЕНИЕ РЕЗУЛЬТАТОВ
save([path_model 'net.mat'], 'net');