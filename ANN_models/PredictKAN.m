function predict = PredictKAN(inp)
    [~, answer] = system(inp);
    answer(1) = '';
    answer(length(answer)) = '';
    answer(length(answer)) = '';
    answer = strsplit(answer, ' ');
    predict = ones(1, 20);
    for i = 1 : 20
        predict(i) = str2num(answer{i});
    end
end