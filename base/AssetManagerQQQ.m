%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 该类用于模拟交易的资金管理，包含了折溢价操作的所有方法
%   method:
%       新增品种
%       isOk = addTypes(obj, configInfo, w , netvalue )
%           configInfo: 包含母基金的信息.
%           w: 归一化权重
%           netvalue: 建仓当天母基金净值
%
%       判断能否做折价
%       [isOk,pos] = canDoZj(obj, OF, cost)
%           cost: 需要的资金
%
%       进行折价操作
%       doZj(obj, OF, cost, retrive, num)
%           retrive: 赎回母基金回收的资金
%           num: 为1时，折价操作后保留一份母基金，否则合并刚购入的分级基金多一份母基金持仓
%       
%       判断能否做溢价
%       [isOk, pos] = canDoYj(obj, OF)
%           返回值: 
%           isOk = 1为满足溢价套利条件， = 2 为因没有分级A、B的持仓而无法套利。
%
%       进行溢价操作
%       doYj(obj, OF, profit)
%           profit: 本次操作的盈利额， profit = gain - cost
%
%       拆分母基金，当 canDoYj(obj,OF) 返回的isOK为2时，即应调用该函数进行拆分操作
%       doSpl(obj,OF)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef AssetManagerQQQ < handle   %维护母基金和分级资金的状态，充分利用资金，连续折价时，将所有2/3的资金都直接持仓母基金进行套利
    properties
        types           % 母基金状态：申购、申购限制中、赎回、赎回限制中、自由态
        holdings        % 持仓份数
        handleRate      % 持仓比
        initAsset       % 开始投入的资金
        typeNums        % 基金品总数
        shMoney
        shMoneyFreez
        validMoney    %可用资金
        
        Info            % 品种信息
    end
    
    properties( Dependent )
        netAsset
    end
    
    methods
        function obj = AssetManagerQQQ(initAsset,handleRate)
            obj.initAsset = initAsset;
            obj.validMoney = initAsset;
            obj.handleRate = handleRate;
            obj.holdings = [];
            obj.types = [];
            obj.Info = [];
            obj.typeNums = 0;
            obj.shMoneyFreez = 0;
            obj.shMoney = 0;
            % log 
            fprintf('-初始化 投入资金 %d.\n', obj.validMoney );
        end
        
        function isOk = addTypes(obj, configInfo, w , netvalue )
            obj.types = [obj.types Type(configInfo.name)];
            obj.Info = [obj.Info configInfo];
            holding = obj.initAsset * obj.handleRate * w / 2 / netvalue;      % 计算购买的份额
            holding = bitset( floor( holding ),1,0);                          % 份额必须是整数,而且是偶数, 将最后一位置0
            obj.holdings = [obj.holdings holding];
            obj.validMoney = obj.validMoney - netvalue * holding * 2;            
            obj.typeNums = obj.typeNums + 1;
            isOk=1; 
            
            % log 
            fprintf('--建仓购入 %d（权重：%.2f） %d 份（净值%f）, 剩余现金 %f .\n', configInfo.name,w, holding, netvalue, obj.validMoney );
        end        
            
        %每日交易结束后，更新母基金状态
        %无参数
        function isOk = updateState(obj)     %每日交易结束后状态的持有指数的状态变化，分级基金不用考虑
            for i = 1:obj.typeNums 
                obj.types(i).lastOp = obj.types(i).curOp;
                if obj.types(i).lastOp == Type.NONE2 || obj.types(i).lastOp == Type.ZHEJIA2
                    obj.types(i).curOp = Type.NONE2;
                else
                    obj.types(i).curOp = Type.NONE1;
                end
            end
            % log
            fprintf('-交易日结算,当天现金 %.2f, 解冻资金 %.2f ，总现金 %.2f \n', obj.validMoney, obj.shMoney, obj.validMoney+obj.shMoney );
            obj.validMoney = obj.validMoney + obj.shMoney;
            obj.shMoney = obj.shMoneyFreez;
            obj.shMoneyFreez = 0;
            isOk = 1;    
        end
        
        function [isOk,pos] = canDoZj(obj, OF, cost)
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
                if obj.validMoney < cost   
                    isOk = -1;
                else
                    
                    isOk = 1;
                end
            else        %剩余的两种状态 都是持有2倍母基金的状态
                if obj.validMoney < 2*cost
                    isOk = -2;
                else
                    isOk = 2;
                end
            end
        end
        
        function  doZj(obj, OF, cost, retrive, num)   
            pos = obj.find(OF);
            if num == 1
                obj.validMoney = obj.validMoney - cost;%买入分级基金，花费掉一份资金
                obj.shMoneyFreez = obj.shMoneyFreez + retrive;
                obj.types(pos).curOp = Type.ZHEJIA1;
            else
                if obj.types(pos).lastOp == Type.NONE2 || obj.types(pos).lastOp == Type.ZHEJIA2   % 持仓2份母基金的情况
                    obj.validMoney = obj.validMoney - 2*cost;
                    obj.shMoneyFreez = obj.shMoneyFreez + 2*retrive;
                else
                    obj.validMoney = obj.validMoney - cost;
                    obj.shMoneyFreez = obj.shMoneyFreez + retrive;
                end
                obj.types(pos).curOp = Type.ZHEJIA2;%合并AB份额*2，但可能是只套利了一份母基金，也可能套利了两份母基金，得视前一交易日的具体情况
                
            end
        end
        
        function [isOk, pos] = canDoYj(obj, OF)
            pos = obj.find(OF);
            if pos == -1;
                error(['没有母基金 %d' num2str(OF)]);
            end
            lastOp = obj.types(pos).lastOp;
            
            %溢价套利是卖出子基金A，B，同时拆分仓中的母基金并申购新的相同份额的母基金
            %因为存在盲拆，所以一般情况下，溢价套利可以每个交易日持续不断地进行
            if lastOp == Type.NONE1 || lastOp == Type.YIJIA1 || lastOp == Type.YIJIA2 || lastOp == Type.ZHEJIA1
                isOk = 1;
            else
                isOk = 2;
            end
        end
        
        function doYj(obj, OF, profit)  %%由于申购是在每日交易结束后才开始扣费，所以资金没影响
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA1;
            obj.validMoney = obj.validMoney + profit;
        end
        
        function doSpl(obj,OF)  %%分拆一半母基金
            pos = obj.find(OF);
            obj.types(pos).curOp = Type.YIJIA2;
            % log
            fprintf('--母基金 %d 拆分\n', OF ); 
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
        
                    
            
                
                
            