function [result, answer] = PredictData(net, input_data, thresh)
    % net - обученная модель
    % input_data - набор из 4 нормированных значений: [день недели, тип дня, номер недели, номер отсчета за день]
    % thresh - порог
    result = net(input_data');
    for i = 1:length(result)
        if (result(i) > thresh)
            answer(i) = 1;
        else
            answer(i) = 0;
        end
    end
end