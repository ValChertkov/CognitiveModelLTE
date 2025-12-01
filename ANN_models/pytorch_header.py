import torch
import torch.nn as nn
import numpy as np
import pandas as pd
import time
import math
import matplotlib.pyplot as plt


class PositionalEncoding(nn.Module):

    def __init__(self, d_model, max_len=5000):
        super(PositionalEncoding, self).__init__()
        pe = torch.zeros(max_len, d_model)
        position = torch.arange(0, max_len, dtype=torch.float).unsqueeze(1)
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        pe = pe.unsqueeze(0).transpose(0, 1)
        self.register_buffer('pe', pe)

    def forward(self, x):
        return x + self.pe[:x.size(0), :]


# Модель трансформера
class TransAm(nn.Module):

    # Конструктор параметров
    def __init__(self, feature_size=250, num_layers=10, dropout=0.1, _nhead=5):
        super(TransAm, self).__init__()
        self._nhead = _nhead
        self.model_type = 'Transformer'
        self.src_mask = None
        self.pos_encoder = PositionalEncoding(feature_size)
        self.encoder_layer = nn.TransformerEncoderLayer(d_model=feature_size, nhead=_nhead, dropout=dropout)
        self.transformer_encoder = nn.TransformerEncoder(self.encoder_layer, num_layers=num_layers)
        self.decoder = nn.Linear(feature_size, 1)
        self.init_weights()

    # Инициализация весов
    def init_weights(self):
        initrange = 0.1
        self.decoder.bias.data.zero_()
        self.decoder.weight.data.uniform_(-initrange, initrange)

    # Ничего не понял, но здесь что-то важное
    def forward(self, src):
        if self.src_mask is None or self.src_mask.size(0) != len(src):
            device = torch.device("cuda")  # устройство cuda
            mask = self._generate_square_subsequent_mask(len(src)).to(device)
            self.src_mask = mask
        src = self.pos_encoder(src)
        output = self.transformer_encoder(src, self.src_mask)
        output = self.decoder(output)
        return output

    # Генерация какой-то маски
    def _generate_square_subsequent_mask(self, sz):
        mask = (torch.triu(torch.ones(sz, sz)) == 1).transpose(0, 1)
        mask = mask.float().masked_fill(mask == 0, float('-inf')).masked_fill(mask == 1, float(0.0))
        return mask


# Разделение данных на окна
def create_inout_sequences(input_data, tw, output_window):
    inout_seq = []  # инициализация этого странного массива
    L = len(input_data)  # длина входных данных
    for i in range(L - tw):  # проходка по вектору данных
        train_seq = input_data[i: i + tw]  # берем окно
        train_label = input_data[i + output_window: i + tw + output_window]  # и теперь оно же, только смещенное
        inout_seq.append((train_seq, train_label))  # и это все в один массив
    return torch.FloatTensor(inout_seq)


# Разделение данных на тренировочные и тестовые
def get_data(data, split, input_window, output_window, device):
    series = data  # копирование массива зачем-то
    split = round(split * len(series))  # индекс раздела данных
    train_data = series[:split]  # выделение тренировочных данных
    train_data = train_data.cumsum()  # опять какая-то куммулятивная сумма, неважно
    # train_data = 2 * train_data  # бессмысленное увеличение данных
    train_sequence = create_inout_sequences(train_data, input_window, output_window)  # генерация входов-выходов
    train_sequence = train_sequence[:-output_window]

    test_data = series[split:]
    test_data = test_data.cumsum()
    test_data = create_inout_sequences(test_data, input_window, output_window)
    test_data = test_data[:-output_window]

    return train_sequence.to(device), test_data.to(device)


# Получить пакет
def get_batch(source, i, batch_size, input_window):
    seq_len = min(batch_size, len(source) - 1 - i)
    data = source[i:i + seq_len]
    input = torch.stack(torch.stack([item[0] for item in data]).chunk(input_window, 1))
    target = torch.stack(torch.stack([item[1] for item in data]).chunk(input_window, 1))
    return input, target


# Получить пакет наших данных
def my_get_batch(X_train, Y_train, i, batch_size, device):

    input_data = X_train[i: i + batch_size, :]
    input_data = torch.FloatTensor([input_data])
    input_data = input_data.transpose(0, 2)
    input_data = input_data.to(device)

    output_data = Y_train[i: i + batch_size, :]
    output_data = torch.FloatTensor([output_data])
    output_data = output_data.transpose(0, 2)
    output_data = output_data.to(device)

    return input_data, output_data


# Тренировка модели
def train(train_data, model, batch_size, optimizer, criterion, epoch, scheduler, input_window):
    model.train()  # режим тренировки
    total_loss = 0.
    start_time = time.time()

    for batch, i in enumerate(range(0, len(train_data) - 1, batch_size)):
        data, targets = get_batch(train_data, i, batch_size, input_window)
        optimizer.zero_grad()
        output = model(data)
        loss = criterion(output, targets)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 0.7)
        optimizer.step()
        total_loss += loss.item()
        log_interval = int(len(train_data) / batch_size / 5)
        if batch % log_interval == 0 and batch > 0:
            cur_loss = total_loss / log_interval
            elapsed = time.time() - start_time
            print('| epoch {:3d} | {:5d}/{:5d} batches | lr {:02.10f} | {:5.2f} ms | '
                  'loss {:5.7f}'.format(epoch, batch, len(train_data) // batch_size, scheduler.get_lr()[0],
                                        elapsed * 1000 / log_interval, cur_loss))
            total_loss = 0
            start_time = time.time()


# Тренировка модели с нашими данными
def my_train(X_train, Y_train, model, batch_size, optimizer, criterion, epoch, scheduler, device):
    model.train()  # режим тренировки
    total_loss = 0.  # общие потери счетчик
    all_loss = []
    for batch, i in enumerate(range(0, len(X_train) - 1, batch_size)):
        input_data, output_data = my_get_batch(X_train, Y_train, i, batch_size, device)
        optimizer.zero_grad()
        output = model(input_data)

        # make_dot(output, params=dict(list(model.named_parameters()))).render(filename="D:/keke.png")

        loss = criterion(output, output_data)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 0.7)
        optimizer.step()
        total_loss += loss.item()
        log_interval = int(len(X_train) / batch_size / 5)
        if batch % log_interval == 0 and batch > 0:
            cur_loss = total_loss / log_interval
            print('| epoch {:3d} | {:5d}/{:5d} batches | lr {:02.10f} | loss {:5.7f}'.
                  format(epoch, batch, len(X_train) // batch_size, scheduler.get_lr()[0], cur_loss))  # отчет
            total_loss = 0  # сброс потерь снова на ноль
            all_loss.append(cur_loss)
    return all_loss


def evaluate(eval_model, data_source, criterion, input_window):
    eval_model.eval()  # Turn on the evaluation mode
    total_loss = 0.
    eval_batch_size = 1000
    with torch.no_grad():
        for i in range(0, len(data_source) - 1, eval_batch_size):
            data, targets = get_batch(data_source, i, eval_batch_size, input_window)
            output = eval_model(data)
            total_loss += len(data[0]) * criterion(output, targets).cpu().item()
    return total_loss / len(data_source)


def my_evaluate(eval_model, X_test, Y_test, criterion, device):
    eval_model.eval()  # режим оценки
    total_loss = 0.
    eval_batch_size = 1000
    with torch.no_grad():
        for i in range(0, len(X_test) - 1, eval_batch_size):
            input_data, output_data = my_get_batch(X_test, Y_test, i, eval_batch_size, device)
            output = eval_model(input_data)
            total_loss += len(input_data[0]) * criterion(output, output_data).cpu().item()
    return total_loss / len(X_test)


def model_forecast(model, seqence, input_window, output_window, device):
    model.eval()
    total_loss = 0.
    test_result = torch.Tensor(0)
    truth = torch.Tensor(0)
    seq = np.pad(seqence, (0, 3), mode='constant', constant_values=(0, 0))
    seq = create_inout_sequences(seq, input_window, output_window)
    seq = seq[:-output_window].to(device)
    seq, _ = get_batch(seq, 0, 1, input_window)
    with torch.no_grad():
        for i in range(0, output_window):
            output = model(seq[-output_window:])
            seq = torch.cat((seq, output[-1:]))
    seq = seq.cpu().view(-1).numpy()
    return seq


# Получение нужных последовательностей для теста
def forecast_seq(model, sequences, input_window):
    start_timer = time.time()
    model.eval()
    forecast_seq_ = torch.Tensor(0)
    actual = torch.Tensor(0)
    with torch.no_grad():
        for i in range(0, len(sequences) - 1):
            data, target = get_batch(sequences, i, 1, input_window)
            output = model(data)
            forecast_seq_ = torch.cat((forecast_seq_, output[-1].view(-1).cpu()), 0)
            actual = torch.cat((actual, target[-1].view(-1).cpu()), 0)
    timed = time.time() - start_timer
    print(f"{timed} sec")
    return forecast_seq_, actual


def my_forecast_seq(model, sequences, input_window):
    start_timer = time.time()  # замер времени
    model.eval()  # модель в режим оценки
    forecast_seq_ = torch.Tensor(0)
    actual = torch.Tensor(0)
    with torch.no_grad():
        for i in range(0, len(sequences) - 1):
            data, target = get_batch(sequences, i, 1, input_window)
            output = model(data)
            forecast_seq_ = torch.cat((forecast_seq_, output[-1].view(-1).cpu()), 0)
            actual = torch.cat((actual, target[-1].view(-1).cpu()), 0)
    timed = time.time() - start_timer
    print(f"{timed} sec")
    return forecast_seq_, actual
