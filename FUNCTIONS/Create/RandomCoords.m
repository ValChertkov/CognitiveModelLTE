% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function XY = RandomCoords()

    global REM_gridSize;

    X = randi(REM_gridSize(1));
    Y = randi(REM_gridSize(2));
    XY = [X Y];

end