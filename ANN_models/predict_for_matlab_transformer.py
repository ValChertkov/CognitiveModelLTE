from pytorch_header import TransAm
import torch.nn as nn
import numpy as np
import argparse
import warnings
import torch

# Глобальные настройки
warnings.filterwarnings("ignore")  # обойдемся без предупреждений
device = torch.device("cpu")  # устройство cuda

# Модель
model = TransAm().to(device)  # инициализация модели
criterion = nn.MSELoss()  # функция оценки
model.load_state_dict(torch.load("transformer_model_30ep_250n_0.1drop_5h_0.00005learn.pth",
                                 map_location=device))  # загрузка модели


# Разбор аргументов
def list_of_strings(arg):
    return arg.split(',')


# Перевод данных из тензора во что-то вменяемое
def flatten_list(_2d_list):
    flat_list = []
    for element in _2d_list:
        if type(element) is list:
            for item in element:
                flat_list.append(item)
        else:
            flat_list.append(element)
    return flat_list


parser = argparse.ArgumentParser()
parser.add_argument("-inp", type=list_of_strings)
args = parser.parse_args()
inp = [float(item) for item in args.inp]
inp = (np.array([inp]))
inp = torch.FloatTensor([inp])
inp = inp.transpose(0, 2)
input_data = inp.to(device)
out = model(inp)  # выполнение прогноза
out = np.array(flatten_list(flatten_list(out.cpu().detach().numpy().tolist()))).tolist()
