classdef TickNode
    properties
        code;             % ĸ�������
        netvalue;           % ĸ�����쾻ֵ
        
        fjAPrice;           % �ּ�A�۸�(�������)
        fjAVolume;          % �ּ�A������(�������)
                   
        fjBPrice;
        fjBVolume;
        
        tradeLimitFlag;  % �ǵ�ͣ��ʶ
        time;
        rate;            % �ۺ��������
        margin;          % rate - threshold
    end
    
    methods
        function obj = TickNode()
            obj.tradeLimitFlag = 0;
        end
    end
end