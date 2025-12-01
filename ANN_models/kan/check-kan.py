# https://github.com/team-daniel/KAN
# Проверка обученной модели

# ИМПОРТ
import time

import kan
import torch
from kan import *
from kan import KAN
from matplotlib.pyplot import grid, show, plot, axis, title, figure, ylabel, xlabel
import kan_funcs
import warnings
import matplotlib

matplotlib.use('TkAgg')
warnings.filterwarnings("ignore")

# ПАРАМЕТРЫ
data_size = 800000
test_data_size = 10000
layers = [5, 5, 5, 5, 5, 5, 20]
epochs = 100  # 100
lamb = 0.0001
grid_kan = 3
polyn = 3
batch = 50000
n = 1
loss = kan.torch.nn.MSELoss()
device = kan_funcs.SetDevice()
adr = "data/"

dataset = kan_funcs.LoadData(adr, test_data_size, 1, device)

all_res = []
trains = []
tests = []
for i in range(n):
    n_learn = i + 1  # номер итерации (до)обучения, где 1 - это первое обучение модели
    model_name = '[' + str(n_learn) + '] ' + 'Input ' + str(data_size) + ', Layers ' + str(layers) + ', Lamb ' + str(
        lamb) + ', Grid ' + str(grid_kan) + ', Polyn ' + str(polyn)

    # model_name = '[1] Input 800000, Layers [5, 5, 5, 5, 5, 5, 20], Lamb 0.0001, Grid 3, Polyn 3'

    # ОСНОВНОЙ КОД
    model = KAN(width=layers, grid=grid_kan, k=polyn, device=device)
    # KAN.load_ckpt(model, name=model_name, folder="./model_ckpt")
    model = KAN.loadckpt(path="results-kan/" + model_name)

    print('\n' + kan_funcs.Colors.GREEN + "[Инфо]" + kan_funcs.Colors.ENDC, 'загружена модель', model_name)

    # КРИВЫЕ ОБУЧЕНИЯ
    file = open('results-kan/' + model_name + '.txt', 'r')
    for j in range(epochs):
        line = file.readline().split(' ')
        trains.append(float(line[0]))
        tests.append(float(line[0]))
    print(trains)
    file.close()

    with torch.no_grad():

        # ПОИСК ЛУЧШЕГО ПОРОГА
        # th = np.arange(0, 1.05, 0.05)
        th = [0.5]
        acc = []
        for thi in th:

            start_time = time.time()
            data = dataset['test_input']

            # line = 110
            # line = (line - 1) / 155
            # if abs(line - data[4]) < 0.001:

            # inp = kan.torch.from_numpy(np.array(
            #     [[float(data[0])], [float(data[1])], [float(data[2])], [float(data[3])],
            #      [float(data[4])]]).transpose()).to(device)

            pred = model(data).cpu().detach().numpy()
            # print("--- %s seconds ---" % (time.time() - start_time))

            # model = model.prune(0.06)  # 0.04
            # start_time = time.time()
            # pred = model(dataset['train_input']).cpu().detach().numpy()
            # print("--- %s seconds ---" % (time.time() - start_time))

            pred = np.concatenate(
                [np.diagonal(pred[::-1, :], k)[::(2 * (k % 2) - 1)] for k in
                 range(1 - pred.shape[0], pred.shape[0])])

            pred = pred > thi

            y_test = dataset['test_label'].cpu().detach().numpy()

            y_test = np.concatenate(
                [np.diagonal(y_test[::-1, :], k)[::(2 * (k % 2) - 1)] for k in
                 range(1 - y_test.shape[0], y_test.shape[0])])

            res = 100 * (1 - np.mean(abs(pred - y_test)))
            all_res.append(res)

            acc.append(res)
            # print(thi, "-> accuracy", res, "%")

        acc = np.mean(acc)
        print(th, acc)

        f0 = figure()
        ax0 = f0.add_subplot(111)
        title('Проверка точности: ' + str(res) + "%")
        ax0.plot(range(len(pred)), -1 * pred, range(len(pred)), y_test)
        ax0.axis((1, 100, -1.25, 1.25))
        ax0.grid()

# %% ГРАФИКИ
# f1 = figure()
# ax1 = f1.add_subplot(111)
# title('Динамика точности моделей')
# ax1.plot(range(1, n + 1), all_res)
# ax1.axis((1, n, min(all_res) - 1, 1 + max(all_res)))
# xlabel('Номер эпохи')
# ylabel('Точность, %')
# ax1.grid()

f2 = figure()
ax2 = f2.add_subplot(111)
ax2.plot(range(1, len(trains) + 1), trains, range(1, len(tests) + 1), tests)
ax2.axis((1, len(trains), min(trains) - 0.005, 0.005 + max(trains)))
ax2.legend('train', 'test')
xlabel('Номер итерации')
ylabel('MSE')
ax2.grid()

# %%
# model.plot()
show()
print("Закончилось")
