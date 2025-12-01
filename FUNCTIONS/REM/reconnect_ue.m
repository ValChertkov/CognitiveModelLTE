function err = reconnect_ue(UE_all, eNodeBS_all, UE, eNodeBS1, eNodeBS2)
    result1 = disconnect_ue(UE.RNTI, eNodeBS1.NCellID, UE_all, eNodeBS_all);	% отключение UE от eNodeBS1
    result2 = connect_ue(UE.RNTI, eNodeBS2.NCellID, UE_all, eNodeBS_all);     	% подключение UE к eNodeBS2
    err = 0;
end