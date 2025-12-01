%% Тестим в лоб!
clear all; close all; clc;
disp([datestr(datetime) ': программа запущена'])

%% Параметры
root_path = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\Model_Simple_25_12_2023_testLSTM\';
path = [root_path 'results\'];
path_temp = [root_path 'temp\'];
path_week = [root_path 'week\'];
CellGoal = [3 3]; % номер интересующей ячейки (например, по центру)
Carr_L = 156; % число линий (должно быть 156)
nd = 10; % шаг для отчетов в командном окне
d = 100 * 3600 * 24; % число кадров LTE в сутках
global samples_in_day;
samples_in_day = 10;

%% Загрузка
week = load([path_week 'week.mat']).schedule;
directory = dir(path); % папка с файлами
numFiles = length(directory); % количество файлов
data = struct; % инициализация структуры
data(numFiles - 2).status = []; % инициализация полей под размер
data(numFiles - 2).frame = []; % инициализация полей под размер
cx = CellGoal(1); cy = CellGoal(2); % предвычисление координат (ради оптимизации)
for i = 3 : 10 % numFiles % параллельный цикл по файлам с 3 (1 и 2 - это системное что-то там)
    file = unzip([path directory(i).name], path_temp); % распаковка данных      
    for j = 1 : Carr_L % цикл по линиям
        data(i - 2).status = load(file{1}).OUT.Simp_REM{cx, cy}; % в статус идет состояние слотов
    	data(i - 2).frame = load(file{1}).OUT.frame; % в кадр идет его номер (кадра LTE от начала)
    end
    if (mod(i, nd) == 0)
        n1 = uint16(i / nd);
        n2 = uint16(numFiles / nd);
    	disp(['    - распаковано ' num2str(n1) '/' num2str(n2) ' пакетов' ])
    end
end

disp([datestr(datetime) ': файлы распакованы'])

%% Обработка
for i = 1 : 8 % length(data)
    for j = 1 : length(data(i).status)
        frame = data(i).frame;
        sample_day = mod(frame, d) / d % номер отсчета в течение дня 0...1
        numerday = 1 + fix(frame / d) % номер дня
        out = Predict20(sample_day, 0.5)
    end
end