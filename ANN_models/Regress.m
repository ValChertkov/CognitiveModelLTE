%% Финальная версия скрипта подготовки данных для прогнозирования
%  снятие данных происходит для одной ячейки и всех ее линий
clear all; close all; clc;
disp([datestr(datetime) ': программа запущена'])

%% 0. Настройки
root_path = '..\LTE_simulation_model\';
path = [root_path 'results\'];
path_week = [root_path 'week\'];
path_temp = [root_path 'temp\'];
path_model = [root_path 'model\'];
path_out = ['kan\out\'];
global samples_in_day;

REM_gridSize = load([root_path 'state\save_data.mat']).save_data.REM_gridSize;
REM_size = REM_gridSize(1) * REM_gridSize(2); % общее количество ячеек
% SubCarrier = 5; % номер интересующей нас линии (в модели их около 160)
CellGoal = [3 3]; % номер интересующей ячейки (например, по центру)
days_in_year = 12 * 4 * 7; % дней в году (не 365, потому что у нас в каждом месяце ровно по 4 недели)
samples_in_day = load([root_path 'state\save_data.mat']).save_data.samples_in_day; % отсчетов за день
train_test = 0.8; % разделение данных
interval = 100 * (86400 / samples_in_day); % шаг модели (производное от отсчетов в день)
Carr_L = 156; % число линий (должно быть 156)
d = 100 * 3600 * 24; % число кадров LTE в сутках
nd = 100; % шаг для отчетов в командном окне

disp([datestr(datetime) ': подготовка данных выполнена'])

%% 1. Загрузка данных
directory = dir(path); % папка с файлами
numFiles = length(directory); % количество файлов
data = struct; % инициализация структуры
data(numFiles - 2, Carr_L).status = zeros(1, 20); % инициализация полей под размер
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
    if (mod(i, nd) == 0)
        n1 = uint16(i / nd);
        n2 = uint16(numFiles / nd);
        disp(['    - распаковано ' num2str(n1) '/' num2str(n2) ' пакетов' ])
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
%     [~, order] = sort([data_line.frame], 'ascend'); % отсортировать линию по номерам кадров
%     data_line = data_line(order); % применение сортировки
    for i = 1 : length(data_line) % проходка по одной линии
        samples(i) = mod(data_line(i).frame, d) / d; % номер отсчета в течение дня 0...1
        data_line(i).sample = samples(i); % номер отсчета в течение дня 0...1
        frames(i) = data_line(i).frame / d; % для графика номер кадра -> день
        numdays(i) = 1 + fix(frames(i)); % номер дня
        data_line(i).numday = numdays(i); % номер дня
        statuses(i) = mean(data_line(i).status); % для графика статус кадра как среднее его слотов
    end
    full_data(:, j) = data_line; % расширенная запись линии в массив
end
clear statuses; clear frames; clear order;

disp([datestr(datetime) ': отсчеты первично обработаны'])

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
end
disp([datestr(datetime) ': отсчеты распределены'])

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
clear prepared_X; clear prepared_Y; clear len_plot; clear a; clear b;

disp([datestr(datetime) ': последовательности перемешаны'])

%% 5. Разделение данных
train_test_size = round(train_test * length(prepared_X_rand));
X_train = single(prepared_X_rand(1 : train_test_size, :));
Y_train = single(prepared_Y_rand(1 : train_test_size, :));
X_test = single(prepared_X_rand(train_test_size + 1 : end, :));
Y_test = single(prepared_Y_rand(train_test_size + 1 : end, :));
clear prepared_X_rand; clear prepared_Y_rand;

disp([datestr(datetime) ': выполнено разделение train-test'])

%% 6. Сохранение
mkdir(path_out); % пересоздание каталога
save([path_out 'X_test.mat'], 'X_test');
save([path_out 'Y_test.mat'], 'Y_test');
save([path_out 'X_train.mat'], 'X_train');
save([path_out 'Y_train.mat'], 'Y_train');

disp([datestr(datetime) ': файлы сохранены'])
