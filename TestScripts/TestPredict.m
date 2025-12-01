%% Смотрим данные прогнозирования от Валерия Михайловича
clear all; close all; clc;
disp([datestr(datetime) ': программа запущена'])

%% Параметры
root_path = 'D:\PSU\LTE\LTE-model-PSU-new\LTE-model-PSU\Model_Simple_25_12_2023_testLSTM_paper\';
% root_path = 'd:\workspace\MATLAB\LTE-model-PSU\Model_Simple_25_12_2023_testLSTM\';

path = [root_path 'results\'];
path_temp = [root_path 'temp\'];
Carr_L = 156; % число линий (должно быть 156)
nd = 10; % шаг для отчетов в командном окне

%% Загрузка
directory = dir(path); % папка с файлами
numFiles = length(directory); % количество файлов
data = struct; % инициализация структуры
% data(numFiles - 2).estimate = zeros(25, 20); % инициализация полей под размер
n = 1;
for i = 3 : numFiles % параллельный цикл по файлам с 3 (1 и 2 - это системное что-то там)
    file = unzip([path directory(i).name], path_temp); % распаковка данных    
    if (load(file{1}).OUT.active_SU == 1) % если был прогноз
        data(n).estimate = uint8(load(file{1}).OUT.out_predict); % забираем оценку
        n = n + 1;
        if (mod(i, nd) == 0)
            n1 = uint16(i / nd);
            n2 = uint16(numFiles / nd);
            disp(['    - распаковано ' num2str(n1) '/' num2str(n2) ' пакетов' ])
        end
    end
end

disp([datestr(datetime) ': файлы распакованы'])

%% Оценка
L = 25 * 20;
M = length(data);
e = zeros(1, M);
for i = 1 : M
    e(i) = 1 - (sum(sum(data(i).estimate)) / L);
end
em = mean(e)
sko = std(e)
per = M / (numFiles - 2)

figure(1)
    area(e)
%     title('Средние точности прогноза по кадрам')
    xlabel('Номер файла')
    ylabel('acc')
    axis([1 M 0 1])
    grid on