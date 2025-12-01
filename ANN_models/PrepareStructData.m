function data = PrepareStructData(L1, L2)

    %% ИНИЦИАЛИЗАЦИЯ СТРУКТУРЫ ПОД РАЗМЕР ДАННЫХ
    disp([datestr(datetime) ': инициализация структуры ' num2str(L1) ' x ' num2str(L2)])
    data = struct;
    parfor i = 1 : L1
        for j = 1 : L2
            data(i, j).status = uint8(zeros(1, 20)); % слоты кадра
            data(i, j).frame = uint64(0); % номер кадра
            data(i, j).line = single(0); % номер линии
            data(i, j).coord_cell = uint8([0, 0]); % координаты ячейки
        end
    end

end