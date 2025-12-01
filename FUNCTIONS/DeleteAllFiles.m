% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function DeleteAllFiles(what)

    files = dir(['*.' what]);
    for i = 1:length(files)
    	delete(files(i).name);
    end
    
end