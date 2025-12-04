function predict = PredictKAN(inp)
    [~, answer] = system(inp);
    
    answer(length(answer)) = '';
    answer(length(answer)) = '';
    answer = strsplit(answer, ' ');
    predict = ones(1, 20);
    kol = length(answer);
    if kol > 21
        idx = kol-19;
        answer{idx} = answer{idx}(3:end);
    end
    for i = 1 : 20
        predict(20-i+1) = str2num(answer{kol-i+1});
    end
end