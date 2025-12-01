function CreateSU()

    global UE;
    global number_UE;
    global number_SU;
    global samples_in_day;

    for i = number_UE + 1 : number_UE + number_SU
        UE{i} = CreateUE(i, RandomCoords(), 0, i, 23, 'SU');
        UE{i}.home_time = randi([1 round(0.3 * samples_in_day)]);
        UE{i}.work_time = UE{i}.home_time + randi([round(0.4 * samples_in_day) round(0.4 * samples_in_day)]);
        UE{i}.trajectory = [0 UE{i}.position];
    end
    
end