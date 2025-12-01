function out = Predict20(in, th)

    %% Прогнозирование состояния кадра на основе:
    % in = [день недели, тип дня, неделя месяца, текущий отсчет времени, номер линии]
    % th = порог для бинаризации, если NaN - не бинаризуется
    % диапазон всех данных строго 0...1

    % для отдельной проверки

    %% Вызов скрипта Python с обученной моделью
	global samples_in_day;
    src = "predict_for_matlab.py";
    args = " -in " + in(1) + "," + in(2) + "," + in(3) + "," + in(4)  + "," + in(5);
    temp = cell(pyrunfile(src + args, 'out'));
    out = single(cell2mat(cell(temp{1, 1})));

    %% Возможная бинаризация
    if (~isnan(th))
        out = single(out > th);
    end

end