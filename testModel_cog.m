%% ЗАПУСК ИМИТАЦИОННОЙ МОДЕЛИ LTE

% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 01.12.2025

%% Перед запуском
close all; clc; clear all; % очистить рабочие области
warning('off'); % отключить лишние предупреждения

%% Добавляем пути к функциям модели
addpath('./FUNCTIONS/Create')
addpath('./FUNCTIONS/REM')
addpath('./FUNCTIONS/Draw')
addpath('./FUNCTIONS/SU')
addpath('./FUNCTIONS')
addpath('./ANN_models')

%% удалить все H5 и ZIP файлы
DeleteAllFiles('zip'); 
DeleteAllFiles('h5'); % 

%% Настройка директорий модели
name = 'LTE_simulation_model'; % название модели
root_folder = [name '/'];
folder = [root_folder 'results/']; % каталог для сохранения результатов
folder_week = [root_folder 'week/']; % каталог для сохранения календаря
folder_state = [root_folder 'state/']; % каталог для сохранения исходных данных
mkdir(root_folder); mkdir(folder); mkdir(folder_week); mkdir(folder_state) % пересоздание каталогов

%% Глобальные переменные
global REM_gridstep; global REM_gridSize; 
global original; global ref_sesions;                                                                                                       
global Freq_DL; global Freq_UL; global KOL_RB;                                                                                                      
global UE; global number_UE; global number_SU; 
global eNodeBS; 
global flag_gen_rem; global flag_move;                                                      
global all_time;                                                       
global week;                                                            
global stepik; 
global days_in_week;
global days_in_type;
global week_in_month;
global samples_in_day;
global days_in_year;
global years;
global noise_p;
global old_time;
global PercenDataSU;
global out_predict;
global out_flag_active_SU;

prediction_bool = false;

%% Иинициализация и расчет переменных (или загрузка из файла) 
CreateConstants(folder_state, folder_week, true); % true - загрузка из файла, false - в функции параметры

%% Сохранение состояния
save([folder_state 'UE.mat'], 'UE');
save([folder_state 'eNodeBS.mat'], 'eNodeBS');
save_data = struct;
save_data.samples_in_day = samples_in_day;
save_data.years = years;
save_data.KOL_RB = KOL_RB;
save_data.REM_gridstep = REM_gridstep;
save_data.REM_gridSize = REM_gridSize;
save_data.Freq_DL = Freq_DL;
save_data.Freq_UL = Freq_UL;
save_data.noise_p = noise_p;
save_data.number_SU = number_SU;
save([folder_state 'save_data.mat'], 'save_data');
clear save_data;

%% Рабочий цикл
tStart = tic; % время запуска цикла                                                    
persent = 0; % прогресс
old_time = -1;
out_predict(25, 20) = 0;
out_flag_active_SU = 0;

for time = 0 : stepik : years * stepik * samples_in_day * days_in_year
    flag_move = false;
    t1 = MoveUE(time);          
    flag_gen_rem = false;
    if (flag_move == true)
        t2 = Reconn_simp();
    else
        t2 = 0;
    end
    t3 = ChangeStatusUE(time);	
    if (flag_gen_rem == true)  
            t4 = AddBSToREM(time);        
            t5 = AddUEToREM(time);
            [Simp_REM, t6] = GenerateSimpREM(false, time);
            IterationDraw(true, Simp_REM);
            [size_f, t7] = SaveSimpREM_HDF5(Simp_REM, time, name, folder, prediction_bool);
            Survey(time, t1, t2, t3, t4, t5, t6, t7, size_f);
            Report(time, tStart);
%             DrawREM();
    end 
end
tEnd = toc(tStart);                                                 
disp(['Время моделирования: ' num2str(tEnd) ' сек'])                    