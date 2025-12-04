# https://github.com/team-daniel/KAN
# Загрузка данных и обучение модели

# ИМПОРТ
import os
import kan
from kan import KAN
from matplotlib.pyplot import show, title, figure
import numpy as np
import kan_funcs
import warnings
import matplotlib

matplotlib.use('TkAgg')
warnings.filterwarnings("ignore")
os.environ["CUDA_LAUNCH_BLOCKING"] = "1"
os.makedirs('results-kan', exist_ok=True)


# ОЦЕНКА ПОТЕРЬ ПРИ ОБУЧЕНИИ
def TrainMSE():
    with kan.torch.no_grad():
        predictions = model(dataset['train_input'][0:test_data_size])
        mse = kan.torch.nn.functional.mse_loss(predictions, dataset['train_label'][0:test_data_size])
    return mse


# ОЦЕНКА ПОТЕРЬ ПРИ ВАЛИДАЦИИ
def TestMSE():
    with kan.torch.no_grad():
        predictions = model(dataset['test_input'][0:test_data_size])
        mse = kan.torch.nn.functional.mse_loss(predictions, dataset['test_label'][0:test_data_size])
    return mse


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
adr = "out/"

params = 0
for i in range(len(layers) - 1):
    params = params + layers[i] * layers[i + 1]
print('Количество параметров:', params * (grid_kan + polyn))  # 1350

# ОСНОВНОЙ КОД
for i in range(n):
    n_learn = i + 1  # номер итерации (до)обучения, где 1 - это первое обучение модели
    model_name = 'Input ' + str(data_size) + ', Layers ' + str(layers) + ', Lamb ' + str(
        lamb) + ', Grid ' + str(grid_kan) + ', Polyn ' + str(polyn)
    dataset = kan_funcs.LoadData(adr, data_size, n_learn, device)

    model = KAN(width=layers, grid=grid_kan, k=polyn, device=device)
    if n_learn > 1:
        temp_name = '[' + str(n_learn - 1) + '] ' + model_name
        KAN.load_ckpt(model, name=temp_name)
        print('\n' + kan_funcs.Colors.GREEN + "[Инфо]" + kan_funcs.Colors.ENDC, 'загружена модель', temp_name)

    results = model.fit(
        dataset, metrics=(TrainMSE, TestMSE), loss_fn=loss,
        steps=epochs, lamb=lamb, batch=batch, lr=1.0 / (i + 1))

    print(kan_funcs.Colors.CYAN + 'MSE (train)' + kan_funcs.Colors.ENDC, results['TrainMSE'])
    print(kan_funcs.Colors.CYAN + 'MSE (test) ' + kan_funcs.Colors.ENDC, results['TestMSE'])

    # ГРАФИКИ
    f1 = figure()
    ax1 = f1.add_subplot(111)
    data_len = len(results['TrainMSE'])
    ax1.plot(range(data_len), results['TestMSE'], range(data_len), results['TrainMSE'])
    title(model_name)
    ax1.grid()
    ax1.legend(('train', 'test'))

    # ПРОВЕРКА
    f2 = figure()
    ax2 = f2.add_subplot(111)
    pred = kan.np.mean(model(dataset['test_input'][0:test_data_size]).cpu().detach().numpy() > 0.5, axis=1)
    real = kan.np.mean(dataset['test_label'][0:test_data_size].cpu().detach().numpy(), axis=1)
    err = kan.np.mean(abs(pred - real))
    acc = 100 * (1 - err)
    print("Accuracy (tr 0.5) = ", acc, "%")
    ax2.plot(range(len(pred)), pred, range(len(real)), real)
    title('Сравнение (ср. загруженность линий) ' + str(acc))
    ax2.legend(('model', 'test'))
    ax2.axis((0, 150, -0.2, 1.2))
    ax2.grid()

    # СОХРАНЕНИЕ
    model_name = '[' + str(n_learn) + '] ' + model_name
    model.saveckpt('results-kan/' + model_name)
    print(kan_funcs.Colors.GREEN + "[Инфо]" + kan_funcs.Colors.ENDC, 'сохранена модель', model_name)
    f1.savefig('results-kan/' + model_name + '.png')
    file = open('results-kan/' + model_name + '.txt', 'w')
    for j in range(len(results['TrainMSE'])):
        file.write(str(results['TrainMSE'][j]) + ' ' + str(results['TestMSE'][j]) + '\n')
    file.close()

    show()
