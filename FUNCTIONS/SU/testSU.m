close all; clc; clear all;
time = 0;
% Определение занятости ресурсных блоков в стуртуре одного кадра
RB_DL = {[], [], [], [], [], [], [], [], [], []};
NDLRB = 6; 
%for i=1:10
%    RB(i) =  randi(NDLRB);
%end
RB = [2,5,1,2,1,1,5,5,2,6];

for i=1:10
   aaa = randperm(NDLRB,RB(i));
   aaa = aaa';
   aaa = aaa - 1;
   RB_DL{i} = aaa;
end

% Генерация сигнала и ресурсной сетки от базовой станции
% Параметры базовой станции 
rmc = lteRMCDL('R.6');      % Генерация параметров базовой станции из модели R.4
rmc.NCellID = 1;      % ID базовой станции
rmc.TotSubframes = 10;      % Число сгенерированных подкадров (10 подкадров составляют 1 кадр)
rmc.NSubframe = 0;
rmc.PDSCH.RNTI = 61;        % Идентификатор ресурсного блока данных 
rmc.NFrame = 0;          % Номер кадра
rmc.PDSCH.PRBSet = RB_DL;
rmc.NDLRB = NDLRB;
rmc.CellRefP = 1; 
rmc.PDSCH.RVSeq = [0 1 2 3];
rmc.OCNGPDSCH.Modulation = '16QAM';
% Генерация выходного сигнала
[signal, txGrid, rmc_out] = lteRMCDLTool(rmc,[1;1;0;1]);

%mesh(abs(txGrid));

% определение пустого ресурсного блока
j = 0;
for i=0:19
    RR =  txGrid(13:24,i*7+1:(i+1)*7);
    ww = abs(RR(:));
    empy_RE = sum(ww==0);
    if (empy_RE > 78)
        j = j + 1;
        empy_RB(j,1) = i;
        empy_RB(j,2) = empy_RE;
    end
end

M = 16;
k = log2(M);
data = randi([0 1],12*7*4,1);

b1 = hex2poly('5f9e3985','ascending'); %SU1 UUID
b2 = hex2poly('342fd71c','ascending'); %SU2 UUID

b3(32) = 0;
b3(1:size(b1,2)) = b1(1:size(b1,2));

b4(32) = 0;
b4(1:size(b2,2)) = b1(1:size(b2,2));

txSig(1:32) = b3(1:32);
txSig(33:64) = b4(1:32);

txSig = qammod(data,M,'InputType','bit','UnitAveragePower',true);
%scatterplot(txSig);



SU = reshape(txSig,[12,7]);

%importSU
i = 0;
i = empy_RB(1,1);
figure;
imagesc(abs(txGrid));
txGrid(13:24,empy_RB(1,1)*7+1:(empy_RB(1,1)+1)*7) = SU(1:12,1:7);
figure;
imagesc(abs(txGrid));
rsIndices{10} = [];
pssIndices{10} = [];
sssIndices{10} = [];
pbchIndices{10} = [];
pdschIndices{10} = [];
pdcchIndices{10} = [];
pcfichIndices{10} = [];
phichIndices{10} = [];

for i=0:rmc.TotSubframes-1
    rmc.NSubframe = i;
    rsIndices{i+1} = lteCellRSIndices(rmc,0);  %	Индексы элемента ресурса RS
    pssIndices{i+1} = ltePSSIndices(rmc,0);   %	Индексы элемента ресурса PSS
    sssIndices{i+1} = lteSSSIndices(rmc,0);   %	Индексы элемента ресурса SSS
    pbchIndices{i+1} = ltePBCHIndices(rmc);   %	Индексы элемента ресурса PBCH
    pdschIndices{i+1} = ltePDSCHIndices(rmc,rmc.PDSCH,rmc.PDSCH.PRBSet{i+1});  %Физический нисходящий канал совместно использованный канал (PDSCH) индексы элемента ресурса
    pdcchIndices{i+1} = ltePDCCHIndices(rmc);	%Индексы элемента ресурса PDCCH
    pcfichIndices{i+1} = ltePCFICHIndices(rmc);	%Индексы элемента ресурса PCFICH
    phichIndices{i+1} = ltePHICHIndices(rmc);	%Индексы элемента ресурса PHICH
end

grid(72,140) = 0;
grid(13:24,empy_RB(1,1)*7+1:(empy_RB(1,1)+1)*7) = 6;

for i=1:rmc.TotSubframes
    grid(1008*(i-1)+rsIndices{i}(:)) = 9;
    grid(1008*(i-1)+pssIndices{i}(:)) = 4;
    grid(1008*(i-1)+sssIndices{i}(:)) = 2;
    grid(1008*(i-1)+pbchIndices{i}(:)) = 3;
    grid(1008*(i-1)+pdcchIndices{i}(:)) = 1;
    grid(1008*(i-1)+pcfichIndices{i}(:)) = 8;
    grid(1008*(i-1)+phichIndices{i}(:)) = 7;
    grid(1008*(i-1)+pdschIndices{i}(:)) = 5;
end

figure;
imagesc(grid);

mymap = [   0.75 0.75 0.75; %0 grey
	        1 1 0;          %1 yellow
            1 0 1;          %2 magenta	
            0 1 1;          %3 cyan
            1 0 0;          %4 red
            0 1 0;          %5 green
            0 0.5 0;        %6 green
            0 0 1;          %7 blue
            0 0 0;          %8 white
            1 1 1;]          %9 black
colormap(mymap);
colorbar('Ticks',[0.5 1.33 2.2 3.1 4 4.9 5.8 6.7 7.6 8.5],...
    'TickLabels',{'unused','PDCCH','SSS','PBCH','PSS','PU data','SU data','PHICH','PCFICH','RS'});
% Create ylabel
ylabel('Поднесущая');

% Create xlabel
xlabel('OFDM символ');