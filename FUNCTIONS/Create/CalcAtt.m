% Y. R. Adamovskiy, V. M. Chertkov, R. P. Bohush (Polotsk State University)
% Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)
% 24.12.2021

function attenuation = CalcAtt(Freq_band, draw)

    global REM_gridstep;
    global REM_gridSize;
    
    %% ГЕНЕРАЦИЯ
    N = 2 * [REM_gridSize(1) REM_gridSize(2)]; 
    if (mod(N(1), 2) == 0)
      N(1) = N(1) + 1;
    end
    if (mod(N(2), 2) == 0)
      N(2) = N(2) + 1;
    end
    point_of_emission = round(N / 2);

    Freq = mean(Freq_band) / 1000;                                          
    attenuation{N(1), N(2)} = [];                                           
    for j = 1:N(2)                                                         
        for i = 1:N(1)                                                     
            att = 32.44 + (20 * log10(Freq));                              
            x = (point_of_emission(1) - i)^2;                               
            y = (point_of_emission(2) - j)^2;                               
            dist = REM_gridstep * ((x + y)^0.5) / 1000;                     
            attenuation{i, j} = single(db2pow(-(att + 20 * log10(dist))));  
         end
    end
    att = 1;                                                                
    attenuation{point_of_emission(1), point_of_emission(2)} = att;          
    
    %% ОТРИСОВКА
    if (draw == true)
        figure(111)
            pic = zeros(N(1), N(2));                        
            for i = 1:N(1)                                  
                for j = 1:N(2)                              
                    pic(i, j) = mean(attenuation{i, j});    
                end
            end
            surf(pow2db(pic))
            title('Матрица затуханий сигнала')
            xlabel('X, км')
            ylabel('Y, км')
            colormap(gray)
    end
    
end