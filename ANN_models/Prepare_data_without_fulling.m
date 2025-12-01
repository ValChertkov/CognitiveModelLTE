%% 0. Настройки
clear all; close all; clc;
root_path = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\Model_Simple_25_12_2023\';
path = [root_path 'results\'];
path_week = [root_path 'week\'];
path_temp = [root_path 'temp\'];
path_model = [root_path 'model\'];
path_out = [root_path 'out\'];
path_rem = [root_path 'state\save_data.mat'];

REM_gridSize = load(path_rem).save_data.REM_gridSize; % подгрузка размера сетки
REM_size = REM_gridSize(1) * REM_gridSize(2); % общее количество ячеек
CellGoal = [3 3]; % номер интересующей ячейки (например, по центру)
days_in_year = 12 * 4 * 7; % дней в году (не 365, потому что у нас в каждом месяце ровно по 4 недели)
samples_in_day = load([root_path 'state\save_data.mat']).save_data.samples_in_day; % отсчетов за день
train_test = 0.8; % разделение данных
interval = 100 * (86400 / samples_in_day); % шаг модели (производное от отсчетов в день)
Carr_L = 156; % число линий (должно быть 156)
d = 100 * 3600 * 24; % число кадров LTE в сутках

directory = dir(path); % папка с файлами
numFiles = length(directory); % количество файлов
X = REM_gridSize(1); Y = REM_gridSize(2); % предвычисление координат (ради оптимизации)
data = PrepareStructData((numFiles - 2) * X * Y, Carr_L); % инициализация структуры
n = 1;

disp([datestr(datetime) ': программа запущена'])

%% 1. Загрузка данных
for i = 1 : numFiles - 2 % параллельный цикл по файлам с 3 (1 и 2 - это системное)
    file = unzip([path directory(i + 2).name], path_temp); % распаковка очередного файла
    loaded = load(file{1}).OUT;
    for x = 1 : X
        for y = 1 : Y
            for j = 1 : Carr_L % цикл по линиям
                data(n, j).coord_cell = [x y]; % в ячейку -> координаты
                data(n, j).status = uint8(loaded.Simp_REM{x, y}(j, :)); % в статус -> слоты
                data(n, j).frame = uint64(loaded.frame); % в кадр -> абс. номер кадра LTE
                data(n, j).line = single((j - 1) / (Carr_L - 1)); % в линию -> номер линии
            end
            n = n + 1;
        end
    end
    if (mod(i, 25) == 0)
    	disp([datestr(datetime) ': распаковано ' num2str(uint16(i/25)) '/' num2str(uint16(numFiles/25)) ' пакетов ' num2str(n) ])
    end
end
disp([datestr(datetime) ': файлы распакованы'])

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
    numdays = zeros(1, length(data_line));
    samples = zeros(1, length(data_line));
    statuses = zeros(1, length(data_line)); % отдельный массив статусов для отрисовки
    [~, order] = sort([data_line.frame], 'ascend'); % отсортировать линию по номерам кадров
    data_line = data_line(order); % применение сортировки
    for i = 1 : length(data_line) % проходка по одной линии
        
        samples(i) = mod(data_line(i).frame, d) / d; % номер отсчета в течение дня 0...1
        data_line(i).sample = samples(i); % номер отсчета в течение дня 0...1
        
        frames(i) = data_line(i).frame / d; % для графика номер кадра -> день
        numdays(i) = 1 + fix(frames(i)); % номер дня
        data_line(i).numday = numdays(i); % номер дня
        
        statuses(i) = mean(data_line(i).status); % для графика статус кадра как среднее его слотов
    end
    full_data(:, j) = data_line; % расширенная запись линии в массив
    
    if (j <= 5) % отрисовка первых 3 недель для первых 10 линий (для проверки)
        figure(1)
            subplot(5, 1, j)
                plot(frames, statuses, 'k.', frames, samples, 'r')
                    title(['Линия ' num2str(j)])
                    axis([1 336 -0.25 1.25])
                    xlabel('Номер дня')
                    ylabel('Статус')
                    grid on
                    drawnow
    end
end
clear statuses; clear frames; clear order;
disp([datestr(datetime) ': файлы первично обработаны'])

%% 3. Подготовка данных
week = load([path_week 'week.mat']).schedule; % загрузка расписания
prepared_X = []; % инициализация массива входных данных
prepared_Y = []; % инициализация массива выходных данных
for j = 1 : Carr_L
    data_line = full_data(:, j); % копирование отдельной линии
    prepared_X_line = single(zeros(length(data_line), 5));
    prepared_Y_line = single(zeros(length(data_line), 20));
    frames = single(zeros(1, length(data_line)));
    for i = 1 : length(data_line) % проход по взятой линии
        frames(i) = data_line(i).frame; % для графиков
        num_day = data_line(i).numday; % номер дня
        samp = data_line(i).sample; % номер отсчета в рамках одного дня
        prepared_Y_line(i, :) = data_line(i).status;
        prepared_X_line(i, :) = [week(1, num_day); % день недели
                                 week(2, num_day); % тип дня
                                 week(3, num_day); % номер недели в месяце
                                 data_line(i).sample; % номер отсчета дня
                                 data_line(i).line]; % номер линии 
    end
    prepared_Y = [prepared_Y; prepared_Y_line];
    prepared_X = [prepared_X; prepared_X_line];
    
    frames = frames / d;
    if (j <= 5) % отрисовка первых 3 недель для первых 5 линий (для проверки)   
    figure(2)
        subplot(5, 1, j)
            plot(frames, prepared_Y_line, 'k.', frames, prepared_X_line(:, 1), 'r', frames, prepared_X_line(:, 2), 'g', frames, prepared_X_line(:, 3), 'b', frames, prepared_X_line(:, 4), 'y', frames, prepared_X_line(:, 5), 'm')
                title(['Линия ' num2str(j)])
                axis([1 336 -0.25 1.25])
                xlabel('Номер дня')
                ylabel('Статус')
                grid on
                drawnow
    end
end
disp([datestr(datetime) ' Файлы собраны'])

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
    
% clear prepared_X; clear prepared_Y; clear len_plot; clear a; clear b;
disp([datestr(datetime) ' Данные перемешаны'])
        
%% 5. Разделение данных
train_test_size = round(train_test * length(prepared_X_rand));
X_train = single(prepared_X_rand(1 : train_test_size, :));
Y_train = single(prepared_Y_rand(1 : train_test_size, :));
X_test = single(prepared_X_rand(train_test_size + 1 : end, :));
Y_test = single(prepared_Y_rand(train_test_size + 1 : end, :));
clear prepared_X_rand; clear prepared_Y_rand;
disp([datestr(datetime) ' Данные подготовлены'])

%% 6 Сохранение
mkdir(path_out); % пересоздание каталога
save([path_out 'X_test.mat'], 'X_test');
save([path_out 'Y_test.mat'], 'Y_test');
save([path_out 'X_train.mat'], 'X_train');
save([path_out 'Y_train.mat'], 'Y_train');
disp([datestr(datetime) ' Данные сохранены'])