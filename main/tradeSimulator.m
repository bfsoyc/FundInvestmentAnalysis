%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 交易模拟器，包含了更加灵活的折溢价操作方法
%   method:
%       新增品种
%       pos = addTypes(obj, configInfo, w , netvalue )
%           configInfo: 包含母基金的信息.
%           w: 归一化权重
%           netvalue: 建仓当天母基金净值
%           返回值:
%           pos 新品种插入到的位置
%
%       查询指定品种在结构体中的位置
%       function pos = find(obj,NameStr)
%           NameStr: 母基金代号的字符数组
%
%       判断能否做折价
%       [isOk,pos] = canDoZj(obj, OF, cost)
%           
%           cost: 需要的资金
%
%       进行折价操作
%       doZj(obj, OF, cost, retrive, num)
%           retrive: 赎回母基金回收的资金
%           num: 为1时，折价操作后保留一份母基金，否则合并刚购入的分级基金多一份母基金持仓
%       
%       判断能否做溢价
%       [isOk, pos] = canDoYj(obj, OF)
%           OF: 直接使用代码调用该函数时请用字符数组
%               否则用该母基金在结构体内的位置。
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

classdef tradeSimulator < handle   %维护母基金和分级资金的状态，充分利用资金，连续折价时，将所有2/3的资金都直接持仓母基金进行套利
    properties
        funds           % 存放基金信息的类
        handleRate      % 持仓比
        initAsset       % 开始投入的资金
        typeNums        % 基金品总数
        redeemMoney     % 赎回的金钱
        freezMoney      % 冻结的资金(赎回母基金的资金不能立刻到账)
        validMoney      % 可用资金     
        
        % 时间信息（ 用户必须每日手动更新)
        date
        referTime       % 相对时间
    end    
    
    methods
        function obj = tradeSimulator(initAsset,handleRate)
            obj.initAsset = initAsset;
            obj.validMoney = initAsset;
            obj.handleRate = handleRate;
            obj.typeNums = 0;
            obj.freezMoney = 0;
            obj.redeemMoney = 0;
            obj.funds = [];
            % log 
            fprintf('-初始化 投入资金 %d.\n', obj.validMoney );
        end
        
        function pos = addTypes(obj, configInfo, w , netvalue )
            holding = obj.initAsset * obj.handleRate * w / 2 / netvalue;      % 计算购买的份额

            % 确定3种持仓比下 5:5 6:4 7:3 ， 购入母基金的真实份额 holding
            if configInfo.aShare*5 == configInfo.bShare*5   % 5:5
                M = mod( holding,200 );
                holding = holding - M;
            elseif configInfo.aShare*4 == configInfo.bShare*6  % 6:4
                M = mod( holding,500 );
                holding = holding - M;
            elseif configInfo.aShare*3 == configInfo.bShare*7  % 7:3
                M = mod( holding,1000 );
                holding = holding - M;
            else
                error('未知比例,或检查精度问题');
            end
            
            fund = Fund;
            fund.copyConfig( configInfo );
            fund.holding = holding;
            fund.Aholding = holding*fund.aShare;
            fund.Bholding = holding*fund.bShare;
            obj.funds = [obj.funds fund];
            
            obj.validMoney = obj.validMoney - netvalue * holding * 2;            
            obj.typeNums = obj.typeNums + 1;
            pos = obj.typeNums;             
            % log 
            fprintf('--建仓购入 %d（权重：%.2f） %d 份（净值%f）, 剩余现金 %f .\n', configInfo.name,w, holding, netvalue, obj.validMoney );
        end        
            
        function  updateState(obj,netValue)     % 每日交易结束后状态更新
            fprintf('-交易日结算\n');
            for i = 1:obj.typeNums 
                fund = obj.funds(i);
                fund.lastOPTime = -180;         % 
                fund.freezHolding = 0;    % 重置
                % 如果有溢价套利                
                if fund.cfHolding > 0
                    holding = floor(fund.applyMoney/netValue(i)/(1+fund.applyFee)); 
                    charge = fund.applyMoney - netValue(i)*holding*(1+fund.applyFee);
                    % log
                    fprintf('--实际申购母基金 %d(%.3f) %d 份,找赎 %.2f \n',fund.name, netValue(i), holding, charge);
                    
                    obj.validMoney = obj.validMoney + charge;
                    % 更新持仓
                    fund.holding = fund.holding + holding;
                    fund.freezHolding = holding;    % 今天不能赎回的份额就是昨天的申购份额
                    fund.Aholding = fund.Aholding + fund.cfHolding*fund.aShare;
                    fund.Bholding = fund.Bholding + fund.cfHolding*fund.bShare;
                    
                    fund.cfHolding = 0;
                    fund.applyMoney = 0;
                end
                
                % 如果有折价套利
                if fund.hbAholding > 0
                    gain = netValue(i)*fund.redeemHolding*(1-fund.redeemFee);
                    % log
                    fprintf('--赎回母基金 %d(%.3f) %d 份,实际获利 %.2f .\n',fund.name, netValue(i), fund.redeemHolding, gain);
                    
                    obj.redeemMoney = obj.redeemMoney + gain;
                    
                    % 更新持仓
                    fund.holding = fund.holding + fund.hbAholding/fund.aShare;
                    
                    fund.redeemHolding = 0;
                    fund.hbAholding = 0;
                    fund.hbBholding = 0;
                end                
            end
            
            obj.validMoney = obj.validMoney + obj.freezMoney;
            % log
            fprintf('-当天冻结资金 %.2f, 解冻资金 %.2f ，总现金 %.2f \n\n', obj.redeemMoney, obj.freezMoney, obj.validMoney );    
            
            obj.freezMoney = obj.redeemMoney;
            obj.redeemMoney = 0;  
        end
        
        function dispHolding(obj)
            for i = 1:obj.typeNums
                fund = obj.funds(i);
                fprintf('* 母基金 %d 持仓： %d, 分级A %s 持仓：%d, 分级B %s 持仓： %d \n',...
                    fund.name, fund.holding, fund.fjAName, fund.Aholding, fund.fjBName, fund.Bholding );
            end
        end
        % 请保持APrice, BPrice, AVolume, BVolume 长度一致
        function [premRate, tradeVol, pos] = calPremRate( obj, OF, APrice, BPrice, AVolume, BVolume, predNetvalue )
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('不存在的母基金');
            end
            fund = obj.funds(pos);
            if obj.referTime < fund.lastOPTime + 15  % 该基金距离上一次操作时间间隔小于15s
                premRate = 0;
                tradeVol = 0;
                return;
            end
            % 变量检测
            if ~isrow(APrice) || ~isrow(BPrice)
                error('APrice 与 BPricce 必须是行向量');
            end
            if ~iscolumn(AVolume) || ~iscolumn(BVolume)
                error('AVoluem 与 BVolume 必须是列向量');
            end
            
            %  !!母基金与分级基金的持仓比例会随时间而变动
            % 溢价
            tradeVol =  fund.Aholding/fund.aShare;  % 溢价套利做的量取决与分级基金的持仓
%             if tradeVol == 0   % 2倍折价 将分级基金合并了
%                 tradeVol = 10;    % 设置tradeVol 为非0值，仅仅用于计算溢价率。
%             end
            leftA = tradeVol*fund.aShare;
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            tradeVol = min( sum(AVolume)/fund.aShare, sum(BVolume)/fund.bShare );   % 有可能A与B五档量不足
            if predNetvalue * tradeVol < 1e4    % 申购母基金的金额小于5w
                premRate = 0;
                tradeVol = 0;
                return;
            end
            leftA = tradeVol*fund.aShare;   % 更新了tradeVol, 必须再算一次[AVolume, BVolume]
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            
            AVolume = AVolume/sum(AVolume); % 归一化
            BVolume = BVolume/sum(BVolume);
            premRate = APrice*AVolume*fund.aShare + BPrice*BVolume*fund.bShare - predNetvalue ;  % 等效溢价率
            
            
        end
            
        function [disRate, tradeVol] = calDisRate( obj, OF, APrice, BPrice, AVolume, BVolume, predNetvalue )
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('不存在的母基金');
            end
            fund = obj.funds(pos);
            if obj.referTime < fund.lastOPTime + 15  % 该基金距离上一次操作时间间隔小于15s
                disRate = 0;
                tradeVol = 0;
                return;
            end          
            
            % 变量检测
            if ~isrow(APrice) || ~isrow(BPrice)
                error('APrice 与 BPricce 必须是行向量');
            end
            if ~iscolumn(AVolume) || ~iscolumn(BVolume)
                error('AVoluem 与 BVolume 必须是列向量');
            end
            
            % 折价的时候判断目前资金足够做多少份折价套利比较复杂
            
            % 计算价差, !!母基金与分级基金的持仓比例会随时间而变动
            % 折价,有多少母基金能做就做多少母基金
            tradeVol =  fund.holding - fund.freezHolding ;
            leftA = tradeVol*fund.aShare;
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            tradeVol = min( sum(AVolume)/fund.aShare, sum(BVolume)/fund.bShare );    % 有可能A与B五档量不足,正常情况下，sum(AVolume) == leftA == tradeVol*fund.aShare
            leftA = tradeVol*fund.aShare;       % 更新了 tradeVol 后再算一次
            leftB = tradeVol*fund.bShare;
            [AVolume, BVolume] = calTradeVol( AVolume, BVolume, leftA, leftB );
            
            cost = APrice*AVolume + BPrice*BVolume;
            if cost < 1e4   % 交易额小于5w 放弃该笔交易
                disRate = 0;
                tradeVol = 0;
                return;
            end
            
            AVolume = AVolume/sum(AVolume); % 归一化 （前面的cost判断让此处不会以0为除数)
            BVolume = BVolume/sum(BVolume);
            disRate = APrice*AVolume*fund.aShare + BPrice*BVolume*fund.bShare - predNetvalue ;  % 等效折价率
        end
        
        function profit = doYj(obj, OF, premRate, tradeVol, predNetvalue)  
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('不存在的母基金');
            end
            
            fund = obj.funds(pos);
            gain = (premRate+predNetvalue)*tradeVol*(1-fund.stockFee);
            cost = predNetvalue*tradeVol*(1+fund.applyFee);
            fund.applyMoney = fund.applyMoney + cost;
            profit = gain - cost;           
            obj.validMoney = obj.validMoney + gain - cost;
            % 更新持仓状态
            fund.holding = fund.holding - tradeVol;
            fund.Aholding = fund.Aholding - tradeVol*fund.aShare;
            fund.Bholding = fund.Bholding - tradeVol*fund.bShare;
            fund.cfHolding = fund.cfHolding + tradeVol;
           
            fund.lastOPTime = obj.referTime;    % 更新该基金最近一次操作的时间
            
            % log
            format = [ '--(%d,%2d)申购母基金 %d(pred:%.3f) 预计 %d 份,花费 %.2f \n' ...
                '%12s卖出分级基金盈利 %.2f \n' ...        
                '%12s总现金 %.2f\n' ];
            fprintf(format, obj.date, obj.referTime, fund.name, predNetvalue, tradeVol, cost, ...
                '', gain, ... 
                '', obj.validMoney);
            
        end
        
        function profit = doZj(obj, OF, disRate, tradeVol, predNetvalue)
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            if pos == -1;
                error('不存在的母基金');
            end
            fund = obj.funds(pos);
            cost = (disRate+predNetvalue)*tradeVol*(1+fund.stockFee);
            gain = predNetvalue*tradeVol*(1-fund.redeemFee);
            profit = gain-cost;
            fund.redeemHolding = fund.redeemHolding+tradeVol;       % 该基金赎回的份额，用于当天结算时计算真实收益
            obj.validMoney = obj.validMoney - cost;
            % 更新持仓
            fund.holding = fund.holding - tradeVol;
            if fund.holding < 0
                error(['母基金' num2str(fund.name) '持仓量不足要求的交易量 ' num2str(tradeVol)])
            end

            fund.hbAholding = fund.hbAholding + tradeVol*fund.aShare;
            fund.hbBholding = fund.hbBholding + tradeVol*fund.bShare;
            
            fund.lastOPTime = obj.referTime;    % 更新该基金最近一次操作的时间
            
            % log
            format = [ '--(%d,%2d)赎回母基金 %d(pred:%.3f) %d 份,预计盈利 %.2f \n' ...
                '%12s买入分级基金花费 %.2f \n' ...        
                '%12s总现金 %.2f\n' ];
            fprintf(format, obj.date, obj.referTime, fund.name, predNetvalue, tradeVol, gain, ...
                '', cost, ... 
                '', obj.validMoney);
        end
            
        function splitFund(obj,OF)  %%分拆一半母基金
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            obj.funds(pos).OPStatus = 1;
            M = mod(obj.funds(pos).holding/2,10); 
            cf = obj.funds(pos).holding/2-M;
            aAdd = cf*obj.funds(pos).aShare;
            bAdd = cf*obj.funds(pos).bShare;
            obj.funds(pos).Aholding = obj.funds(pos).Aholding + aAdd;
            obj.funds(pos).Bholding = obj.funds(pos).Bholding + bAdd;
            obj.funds(pos).holding = obj.funds(pos).holding - cf;            
            obj.funds(pos).holdingStatus = 0;            
            % log
            fprintf('--母基金 %d 拆分\n', obj.funds(pos).name ); 
        end
        
        function mergeFund(obj, OF)
            if ischar( OF )
                pos = obj.find(OF);
            else
                pos = OF;
            end
            fund = obj.funds(pos);
            % 合并全部分级基金
            hb = fund.Aholding/fund.aShare;
            fund.holding = fund.holding + hb;
            fund.Aholding = 0;
            fund.Bholding = 0;
            % log
            fprintf('--母基金 %d 通过合并增加 %d 份\n', obj.funds(pos).name, hb ); 
        end
       
        function pos = find(obj,NameStr)
            if ~ischar( NameStr )
                error('请输入母基金代码的字符数组');
            end
            len = length(NameStr);
            if( len > 6 )
                NameStr = NameStr( end-6:end);
            end
            code = str2num( NameStr );
            pos = -1;
            for i = 1:obj.typeNums
                if obj.funds(i).name == code
                    pos = i;
                    return;
                end
            end
        end
        
    end
end
        
                    
            
                
                
            