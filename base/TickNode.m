classdef TickNode
    properties
        muName;             % 母基金代号
        netvalue;           % 母基金当天净值
        
        fjAName;            % 分级A代号
        fjAPrice;           % 分级A价格(多个档次)
        fjAVolume;          % 分家A交易量(多个档次)
        
        fjBName;            
        fjBPrice;
        fjBVolume;
        
        time;
        disRate;            % 折合折溢价率
    end
    
    
end