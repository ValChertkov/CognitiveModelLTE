# https://github.com/team-daniel/KAN
# Имплементация обученной модели
import argparse
import sys

# ИМПОРТ
import kan
from kan import *
import kan_funcs
import warnings

warnings.filterwarnings("ignore")

device = kan_funcs.SetDevice()
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
KAN.load_ckpt(model, name=model_name)

with (torch.no_grad()):
    pred = model(inp).cpu().detach().numpy()
    pred = (pred > 0.5).astype('int')

for i in pred:
    print(i)


