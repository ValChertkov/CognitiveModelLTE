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

device = kan.torch.device("cpu")  # Force CPU to avoid CUDA checkpoint loading issues
data = sys.argv[1].split(',')
inp = kan.torch.from_numpy(
            np.array(
                [[float(data[0])],
                 [float(data[1])],
                 [float(data[2])],
                 [float(data[3])],
                 [float(data[4])]
                 ]).transpose()
            ).to(device)
# print(inp.shape, inp)

model_name = 'test-model'
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
    KAN.load_ckpt(model, name=model_name)
finally:
    kan.torch.load = original_load  # Restore original function

with (kan.torch.no_grad()):
    pred = model(inp).cpu().detach().numpy()
    pred = (pred > 0.5).astype('int')

for i in pred:
    print(i)


