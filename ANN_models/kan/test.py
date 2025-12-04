# https://github.com/team-daniel/KAN
# Имплементация обученной модели
import argparse
import sys

# ИМПОРТ
import numpy as np
import kan
from kan import *
import kan_funcs
import warnings

warnings.filterwarnings("ignore")

script_dir = os.path.dirname(os.path.abspath(__file__))
path_kan = os.path.join(script_dir, "results-kan/")

device = kan_funcs.SetDevice()
data = sys.argv[1].split(',')
inp = kan.torch.from_numpy(
    np.array(
        [[np.float32(data[0])],
         [np.float32(data[1])],
         [np.float32(data[2])],
         [np.float32(data[3])],
         [np.float32(data[4])]
         ], dtype=np.float32
    ).transpose()
).to(device)
# print(inp.shape, inp)

model_name = '[1] Input 800000, Layers [5, 5, 5, 5, 5, 5, 20], Lamb 0.0001, Grid 3, Polyn 3'
layers = [5, 5, 5, 5, 5, 5, 20]
lamb = 0.0001
grid_kan = 3
polyn = 3
loss = kan.torch.nn.MSELoss()

model = kan.KAN(width=layers, grid=grid_kan, k=polyn, device=device)
# Load checkpoint with CPU device mapping to handle CUDA-trained models
# Temporarily patch torch.load to use map_location for CPU
original_load = kan.torch.load
kan.torch.load = lambda *args, **kwargs: original_load(*args, map_location=device, **{k: v for k, v in kwargs.items() if k != 'map_location'})
try:
    model = KAN.loadckpt(path=path_kan + model_name)

    #print('\n' + kan_funcs.Colors.GREEN + "[Инфо]" + kan_funcs.Colors.ENDC, 'загружена модель', model_name)
finally:
    kan.torch.load = original_load  # Restore original function

with (kan.torch.no_grad()):
    pred = model(inp).cpu().detach().numpy()
    pred = (pred > 0.5).astype('int')
print(' ')
for i in pred:
    print(i)


