function out = Predict20_Transformer(in, th)

    %% Прогнозирование состояния кадра на основе:
    % in = [день недели, тип дня, неделя месяца, текущий отсчет времени, номер линии]
    % th = порог для бинаризации, если NaN - не бинаризуется
    % диапазон всех данных строго 0...1

    %% Вызов скрипта Python с обученной моделью
	global samples_in_day;
    src = "predict_for_matlab_transformer.py";
    args = " -inp " + in(1) + "," + in(2) + "," + in(3) + "," + mod(in(4), samples_in_day) / samples_in_day + "," + in(5) + ...
        ",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    temp = cell(pyrunfile(src + args, 'out'));
    out = single(cell2mat(cell(temp)));

    %% Возможная бинаризация
    if (~isnan(th))
        out = single(out > th);
    end

end