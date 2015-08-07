classdef AssetManager < handle   %维护母基金和分级资金的状态，充分利用资金，连续折价时，将所有2/3的资金都直接持仓母基金进行套利
    properties
        types         %母基金状态：申购、申购限制中、赎回、赎回限制中、自由态
        typeNums
        shMoney
        shMoneyFreez
        handleRate
        totalRate
        validMoney    %可用资金
        totalMoney    %总资金
    end
    
    
    methods
        function obj = AssetManager(handle, total)
            obj.types=[];
            len = 0;
            obj.typeNums = len;
            obj.shMoney = 0;
            obj.shMoneyFreez = 0;
            obj.validMoney = len*(total-handle);
            obj.totalMoney = len*total;
            obj.handleRate = handle;
            obj.totalRate = total;
        end
        
        %对于单只基金，每次套利流动的资金实质是持仓资金的一半，CcRate()返回该部分资金占总资金的百分比！！错，是占该品总总资金的百分比！
        function cc = CcRate(obj)
            cc = obj.handleRate/obj.totalRate/2;
        end
        
        %新增品种
        %OF 品种代码，一维数组
        function isOk = addTypes(obj,OF)
            tmp =[];
            len = size(OF,2);
            if len < 1
                isOk=-1; return;
            end

            if obj.typeNums >= 1                %%%%%%%%重置所有基金为初始态%%%%%%%假设性的做法
                for i = 1:obj.typeNums
                    tmp = [tmp Type(obj.types(i).OFName)];
                end
            end
            
            for i=1:len;
                tmp = [tmp Type(OF(i))];
            end
            obj.types = tmp;
            obj.typeNums = obj.typeNums + len;
            obj.shMoney = 0;
            obj.validMoney = obj.typeNums*(obj.totalRate-obj.handleRate);
            obj.totalMoney = obj.typeNums*obj.totalRate;
            isOk=1;
        end
        
        %每日交易结束后，更新母基金状态
        %无参数
        function isOk = updateState(obj)     %每日交易结束后状态的持有指数的状态变化，分级基金不用考虑
            for i=1:obj.typeNums%%??变量作用域
                obj.types(i).lastOp = obj.types(i).curOp;
                if obj.types(i).lastOp == Type.NONE2 || obj.types(i).lastOp == Type.ZHEJIA2
                    obj.types(i).curOp = Type.NONE2;
                else
                    obj.types(i).curOp = Type.NONE1;
                end
            end
            obj.validMoney = obj.validMoney + obj.shMoney;
            obj.shMoney = obj.shMoneyFreez;
            obj.shMoneyFreez = 0;
            isOk = 1;    
        end
        
        %判断是否可做折价操作
        %OF 母基金代码
        function isOk = canDoZj(obj,OF)
            isOk = 0;
            pos = obj.find(OF);
            if pos == 0;
                return;
            end
            if obj.types(pos).lastOp == Type.YIJIA1    %前一天做了溢价，刚申购回来的母基金可以拆分但不能立刻赎回？ 所以不能马上做折价
                return;
            end
            if obj.types(pos).lastOp == Type.NONE1 || obj.types(pos).lastOp == Type.YIJIA2 || obj.types(pos).lastOp == Type.ZHEJIA1
                % YIJIA2 实际上就是回归到初始状态。
                if obj.validMoney < obj.handleRate/2    
                    isOk = -1;
                else
                    isOk = 1;
                end
            else        %剩余的两种状态 都是持有2倍母基金的状态
                if obj.validMoney < obj.handleRate
                    isOk = -2;
                else
                    isOk = 2;
                end
            end
        end
        
        %折价操作
        %OF 母基金代码
        function  doZj(obj,OF,num)
            pos = obj.find(OF);
            if num == 1
                obj.validMoney = obj.validMoney - obj.handleRate/2;%买入分级基金，花费掉一份资金
                obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate/2;
                obj.types(pos).curOp = Type.ZHEJIA1;
            else
                if obj.types(pos).lastOp == Type.NONE2 || obj.types(pos).lastOp == Type.ZHEJIA2   % 持仓2份母基金的情况
                    obj.validMoney = obj.validMoney - obj.handleRate;
                    obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate;
                else
                    obj.validMoney = obj.validMoney - obj.handleRate/2;
                    obj.shMoneyFreez = obj.shMoneyFreez + obj.handleRate/2;
                end
                obj.types(pos).curOp = Type.ZHEJIA2;%合并AB份额*2，但可能是只套利了一份母基金，也可能套利了两份母基金，得视前一交易日的具体情况
            end
        end
        
        function isOk = canDoYj(obj,OF)
            isOk = 0;
            pos = obj.find(OF);
            if pos == -1;
                return;
            end
            lastOp = obj.types(pos).lastOp;
            %溢价套利是卖出子基金A，B，同时拆分仓中的母基金并申购新的相同份额的母基金
            %以为存在盲拆，所以一般情况下，溢价套利可以每个交易日持续不断地进行
            if lastOp == Type.NONE1 || lastOp == Type.YIJIA1 || lastOp == Type.YIJIA2 || lastOp == Type.ZHEJIA1
                isOk = 1;
            else
                isOk = 2;
            end
        end
        
        function doYj(obj,OF)  %%由于申购是在每日交易结束后才开始扣费，所以资金没影响
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA1;
        end
        
        function doSpl(obj,OF)  %%分拆一半母基金
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA2;
        end
        %查询指定品种在types数组中的位置
        %OF 指定品种的母基金代码
        function pos = find(obj,OF)
            if obj.typeNums < 1;
                pos =-1;return 
            end
            for i = 1:obj.typeNums
                if obj.types(i).OFName == OF
                    pos = i;
                    return;
                end
            end
            pos =-1;return;
        end
        
    end
end
        
                    
            
                
                
            