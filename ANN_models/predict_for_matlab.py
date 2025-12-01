from keras.src.saving.saving_api import load_model
import numpy as np
import argparse


def list_of_strings(arg):
    return arg.split(',')


parser = argparse.ArgumentParser()
parser.add_argument("-inp", type=list_of_strings)
args = parser.parse_args()
inp = [float(item) for item in args.inp]
model = load_model('Model_Simple_25_12_2023_LSTM_4l_standart.h5')  # загрузка модели
inp = (np.array([inp]))
out = model.predict(inp).tolist()
