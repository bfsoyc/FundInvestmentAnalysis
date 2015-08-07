classdef Type < handle
    properties
        lastOp
        curOp
        OFName
    end
    properties (Constant)
        NONE1 = 0;    %母基金、AB同比持仓情况下 什么都没做
        YIJIA1 = 1;   %母基金、AB同比持仓情况下 溢价套利
        ZHEJIA1 = 2;  %母基金、AB同比持仓情况下 折价套利
        
        NONE2 = 3;    %母基金持仓情况下 什么都没做
        YIJIA2 = 4;   %母基金持仓情况下 分拆一半母基金，不套利
        ZHEJIA2 = 5;  %母基金持仓情况下 折价套利
    end
    methods
        function obj = Type(arg)
            obj.OFName = arg;
            obj.lastOp = obj.NONE1;
            obj.curOp = obj.NONE1;
        end
    end
end
        
       