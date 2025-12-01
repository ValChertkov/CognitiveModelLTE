% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function rem_simp = REM_gen(r_x, r_y,eNodeBS, time)

    global KOL_RB;
    global Freq_DL;
    global days_in_year;
    global UE;
    global week;
    global out_predict;
    global out_flag_active_SU;

    line_find = 1;
    cntRB = ((((KOL_RB + 1) * 12) * 3)) * 2;

    eNodeBS_max = size(eNodeBS, 2);
    UE_max = size(UE, 2);
    rem(cntRB, 140) = int8(0);
    F(cntRB, 140) = int8(0);
    kol = eNodeBS_max + UE_max;
    for i = 1 : kol
        if (i <= eNodeBS_max)
            x = eNodeBS{i}.position(2);
            y = eNodeBS{i}.position(1);
            buf = eNodeBS{i}.remSimp;
        else
            if (strcmp(UE{i - eNodeBS_max}.type,'PU'))
                x = UE{i - eNodeBS_max}.position(2);
                y = UE{i - eNodeBS_max}.position(1);
                buf = UE{i - eNodeBS_max}.remSimp;
            else
                if (UE{i - eNodeBS_max}.status == 1)
                    x = UE{i - eNodeBS_max}.position(2);
                    y = UE{i - eNodeBS_max}.position(1);
                    if (UE{i - eNodeBS_max}.NCellID == 0)
                        copy = rem(Freq_DL(1, 2) : Freq_DL(1, 2) + 299, :);
                        mytime = mod(floor(time / 8640000), days_in_year) + 1;
                        out_flag_active_SU = 1;
                        for oo = 1 : 25
                            line_find = oo;
                            buf1(oo, :) = find_emp_SU(copy, line_find);

                            % in = [день недели, тип дня, неделя месяца, текущий отсчет времени, номер линии]
                            % (Freq_DL(1,2)+ line_find - 1 ) - вроде как номер
                            % линии в БЗ в которую будут интегрированы данные
                            % SU
                            line_index = (((Freq_DL(eNodeBS{1,1}.freq_band, 2) - 1) / 12) + line_find - 1) / 155;
                            in = [week(1, mytime), week(2, mytime), week(3, mytime), time, line_index ];
                            th = 0.5; % порог бинаризации для прогноза

                            %% ВРЕМЕННО УБРАЛ ИЗ_ЗА НИЗКОЙ СКОРОСТИ
                            % out11(oo, :) = Predict20(in, th); % прогноз с помощью модели
                            out11(oo, :) = zeros(1, 20);


                        end
                        out11 = ~out11;
                        out_predict = xor(out11, buf1); % XOR
                        buf2 = suImport(copy, buf1);
                        buf = rem;
                        buf(Freq_DL(1,2):Freq_DL(1,2)+299,:) = buf2;
                        UE{i - eNodeBS_max}.remSimp = buf;
                        UE{i - eNodeBS_max}.NCellID = -1;
                    else
                        buf = UE{i - eNodeBS_max}.remSimp;
                    end
                end
            end
        end
        dist = 250 * (((x - r_x)^2 + (y - r_y)^2)^0.5);
        if (dist > 1500)
            buf = F;
        elseif (dist > 1250)
            buf = int8(buf > 0);
        end
        rem = max(rem,buf);
    end
    rem_simp = rem;

end