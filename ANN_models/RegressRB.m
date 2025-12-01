clear all; close all; clc;
disp([datestr(datetime) ' Программа запущена'])

%% 0. Настройки
path = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\results_test\';
path_week = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\week_test\';
path_temp = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\temp\';
path_model = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\model\';
REM_size = 7 * 7;    	% общее количество ячеек
SubCarrier = 5;         % номер интересующей нас линии (в модели их около 160)
CellGoal = [3 3];       % номер интересующей ячейки (например, по центру)
days_in_year = 336;     % дней в году (не 365, потому что у нас в каждом месяце ровно по 4 недели)
samples_in_day = 100;	% отсчетов за день
% RB_in_frame = 1;  	% блоков в отсчете
train_test = 0.9;       % разделение данных
interval = 100 * (86400 / samples_in_day); % шаг модели (производное от отсчетов в день)

%% 1. Загрузка данных
% файлы распаковываются и заносятся в табличку
% чтение файла, статусов и кадров
directory = dir(path);              % папка с файлами
numFiles = length(directory);       % количество файлов
data = struct;                    	% структура
data(numFiles - 2).status = [];    	% инициализация под размер
data(numFiles - 2).frame = [];    	% инициализация под размер
cx = CellGoal(1);                   % предвычисление данных ради оптимизации
cy = CellGoal(2);                   % предвычисление данных ради оптимизации
parfor i = 3:numFiles           	% цикл по файлам с 3, потому что 1 и 2 - это системное что-то там
    file = unzip([path directory(i).name], path_temp);                                                       
    data(i - 2).status = load(file{1}).OUT.Simp_REM{cx, cy}(SubCarrier, :);
    data(i - 2).frame = load(file{1}).OUT.frame;
    if (mod(i, 1000) == 0)
    	disp([num2str(uint16(i / 1000)) '/' num2str(uint16(numFiles / 1000)) ' ' datestr(datetime)])
    end
end
disp([datestr(datetime) ' Файлы распакованы'])

%% 2. Проверка данных + график
% кадры в номер отсчета в день
frame = zeros(1, length(data));
frames = zeros(1, length(data));        % отдельный массив номеров кадров для отрисовки по дням недели
statuses = zeros(1, length(data));    	% отдельный массив статусов для отрисовки
[~, order] = sort([data(:).frame], 'ascend');
data = data(order);
for i = 1:length(data)
    data(i).sample = mod(data(i).frame, 8640000) / 8640000;
    data(i).numday = 1 + fix(data(i).frame / 100 / 3600 / 24);
    frames(i) = data(i).frame / 8640000; 
    statuses(i) = mean(data(i).status); 
end
figure(1)
    plot(frames, statuses, 'k')
        title('Данные за неделю')
        axis([0 7 0 1.1])
        xlabel('Номер дня')
        ylabel('Статус')
        grid on

%% 3. Подготовка данных
% дозапись пропущенных данных
week = load([path_week 'week.mat']).schedule;
% prepared_X = zeros(round(data(end).frame) / 10, 4);
% prepared_Y = zeros(round(data(end).frame) / 10, 10);
n = 1;
for i = 1:length(data) - 1
    num_day = 1 + fix(data(i).frame / 100 / 3600 / 24);	% номер дня
    frame = data(i).sample;                           	% отсчет от начала дня
    now_frame = data(i).frame;
    while (now_frame < data(i + 1).frame)              	% пока не наступает следующий отсчет
        prepared_X(n, :) = [                          	% запись параметров дня и номер отсчета
            week(1, num_day); 
            week(2, num_day); 
            week(3, num_day); 
            frame];              
        prepared_Y(n, :) = data(i).status;              % запись статуса
        now_frame = now_frame + interval;
        frame = mod(frame + (1 / samples_in_day), 1);
        n = n + 1;
    end
    if (mod(i, 1000) == 0)
    	disp([num2str(i) ' | ' num2str(n)])
    end
end
prepared_X(n:end, :) = [];
prepared_Y(n:end, :) = [];

%% 4. Разделение данных
train_test_size = round(train_test * length(prepared_X));
X_train = single(prepared_X(1:train_test_size, :));
Y_train = single(prepared_Y(1:train_test_size, :));
X_test = single(prepared_X(train_test_size + 1:end, :));
Y_test = single(prepared_Y(train_test_size + 1:end, :));
disp([datestr(datetime) ' Данные подготовлены'])

%% 4.1 График
figure(2)
    plot((1:length(prepared_Y)) /samples_in_day, mean(prepared_Y'), 'k')
    axis([0 7 0 1.1])
    xlabel('Номер дня')
    ylabel('Статус')
    grid on   
        
%% 3. Обучение
% 1 слой по 100: 585 ит. 0.16 (порог 0.5)
% 2 слоя по 50: 469 ит. 0.12 (порог 0.5)
% 4 слоя по 25: 1000 ит. 0.1 (порог 0.5)
% 5 слоев по 20: 444 ит. 0.099 (порог 0.5)
% 10 слоев по 10: 252 ит. 0.13 (порог 0.5)
% 10 слоев по 20: 332 ит. 0.087 (порог 0.6)
% 5 cлоев 20 10 5 10 20: 266 ит. 0.15
% 3 cлоя 100 100 100: 
% net = fitnet(1000);
net = newff(X_train', Y_train', [20 10]);
net = configure(net, X_train', Y_train');
view(net) 
net.divideParam.trainRatio = 0.8;
net.divideParam.valRatio = 0.1;
net.divideParam.testRatio = 0.1;
net = train(net, X_train', Y_train', 'useParallel', 'yes', 'showResources', 'yes');
    
%% 4. Прогноз
mass_err = []; mass_err_0 = []; mass_err_1 = [];
len = 0.05:0.05:0.95; 
for j = len
    y = mean(net(X_test'));
    err = 0; 
    err_1 = 0; err_1_len = 0;
    err_0 = 0; err_0_len = 0;
    for i = 1:length(y)
        if (y(i) < j)
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