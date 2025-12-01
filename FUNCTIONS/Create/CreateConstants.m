function CreateConstants(folder_state, folder_week, need_load)

    global REM_gridstep; 
    global REM_gridSize; 
    global original; 
    global ref_sesions;                                                                                                       
    global Freq_DL; 
    global Freq_UL; 
    global KOL_RB;                                                                                                      
    global UE; 
    global number_UE; 
    global number_SU; 
    global eNodeBS; 
    global flag_gen_rem; 
    global flag_move;                                                      
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
    global PercenDataSU;
    UE = {}; eNodeBS = {};
    
    %% НЕЗЫБЛЕМЫЕ КОНСТАНТЫ
    days_in_week = 7;                                   % дней в неделе
    days_in_type = 3;                                   % типов дней
    week_in_month = 4;                                  % недель в месяце
    days_in_year = 12 * week_in_month * days_in_week;   % дней в году (12 мес)
    PercenDataSU = 10;                                  % процент SU

    %% ПЕРВЫЙ ЭТАП
    if (need_load == false)                     % если модель создается с нуля, то
        samples_in_day = 864;                       % отсчетов на день (по умолчанию 8640 = 10 с)
        years = 1;                                  % количество лет для имитации                                                     
        number_UE = 5;                              % количество UE на поле (по умолчанию 30)    
        number_SU = 2;                              % количество SU на поле 
        KOL_RB = 25;                                % количество блоков на UE
        REM_gridstep = 250;                         % шаг сетки, м
        REM_gridSize = [5 5];                       % размер сетки, по умолчанию [20 20]
        Freq_DL = [1820000, 937; 
                   1824680, 1249; 
                   1829360, 1561];                  % параметры нисходящей линии     
        Freq_UL = [1720000, 1; 
                   1724680, 313; 
                   1729360, 625];                   % параметры восходящей линии
        noise_p = 0;                                % уровень случайности поведения UE
        week = CreateTimeNew(folder_week, true);    % формирование календаря
    else                                        % если модель загружаеися
        week = load([folder_week 'week.mat']).schedule;
        UE = load([folder_state 'UE.mat']).UE;
        eNodeBS = load([folder_state 'eNodeBS.mat']).eNodeBS;
        samples_in_day = load([folder_state 'save_data.mat']).save_data.samples_in_day;
        years = load([folder_state 'save_data.mat']).save_data.years;
        KOL_RB = load([folder_state 'save_data.mat']).save_data.KOL_RB;
        REM_gridstep = load([folder_state 'save_data.mat']).save_data.REM_gridstep;
        REM_gridSize = load([folder_state 'save_data.mat']).save_data.REM_gridSize;
        Freq_DL = load([folder_state 'save_data.mat']).save_data.Freq_DL;
        Freq_UL = load([folder_state 'save_data.mat']).save_data.Freq_UL;
        noise_p = load([folder_state 'save_data.mat']).save_data.noise_p;
        number_SU = load([folder_state 'save_data.mat']).save_data.number_SU;
        number_UE = size(UE, 2) - number_SU;
    end
    
    %% ВТОРОЙ ЭТАП
    stepik = 100 * (86400 / samples_in_day); % вычисление интервала между отсчетами, в кадрах LTE
    all_time = years * stepik * samples_in_day * days_in_year; % интервал имитации 
    [Freq_band, original] = CaclFreqBands(1720000, 1820000, 15); 
    attenuation = CalcAtt(Freq_band, true); % расчет матрицы ослаблений 
    
    %% ТРЕТИЙ ЭТАП
    if (need_load == false)
        ref_sesions = SessionsVariance(true); % создание расписаний каждого UE                                                                                       	
        CreateAllBS(); % генерация БС (настройки внутри)                                                      
        CreateUEsNewMove(true); % генерация движений PU
        CreateSU(); % генерация SU
        CreateUEsNewSession(true); % генерация звонков PU
    end
    
    %% ФИНАЛ
    REM = CreateREM(); % инициализация REM     
    DrawREM(); % нарисовать исходную REM 

end