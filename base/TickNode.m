classdef TickNode
    properties
        code;             % 母基金代号
        netvalue;           % 母基金当天净值
        
        fjAPrice;           % 分级A价格(多个档次)
        fjAVolume;          % 分家A交易量(多个档次)
                   
        fjBPrice;
        fjBVolume;
        
        time;
        rate;            % 折合折溢价率
    end
    
    
end