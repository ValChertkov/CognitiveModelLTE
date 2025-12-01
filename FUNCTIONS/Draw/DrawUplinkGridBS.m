function DrawUplinkGridBS(txGrid)
    figure()
    imagesc(abs(txGrid))
    title('Ресурсная сетка uplink сигналов eNodeBS')
    xlabel('OFDM символы (в сумме 10 мс)')
    ylabel('Поднесущие частоты (шаг 15 кГц)')
    grid on
    colormap(gray)
end