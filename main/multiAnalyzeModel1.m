%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   该版本读取 config.csv文件
%   操作指定品种(selectMode=1)，并且不支持权重设置
%   收益率计算方式：    需要除以当天的基金持仓品总数，即每天的总资产是恒定的，平均分配到各个品种中。
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function multiAnalyzeModel1()
%% 添加工程目录
Files = dir(fullfile( '..\','*.*'));
for i = 1:length(Files)
    if( Files(i).isdir )
        addpath( ['..\' Files(i).name ])
    end
end
%% 变量设置
bgtyear = 2013;
edtyear = 2015;
init2();
global resultTable fjDailyTable rateTable configTable muDailyTable idxDailyTable rDetialTable statList;

handleRate = [2 3];%2/3、2/4持仓
zjType = 2;     %折价类型 一倍，两倍……
slipRatio = 0;  %N倍滑点率，0时代表不考虑滑点

[selectFund,weight] = getSelectionFund();
selectMode = 0;

%%  读取数据
config = readcsv2('\config.csv', 12);
zsHs300 = csvread('G:\datastore\日线1\SZ399300.csv');
tableLen = length(config{1});    
Src = cell(1,tableLen);
for k = 2:tableLen     %第一行是表头
    
    muName = config{statList.muName}{k};
    % 检查该基金是否要操作
    muCode = str2num(muName(3:end));
    if( selectMode == 1)
        idx =  selectFund == muCode;
        if ( ~sum( idx  ) )
         continue;
        end
    end
    
    fjAName = config{statList.fjAName}{k};      %子基金A名：深交所的以SZ开头
    fjBName = config{statList.fjBName}{k};
    zsName = config{statList.zsName}{k};
    try
        %读取母基金，其分级基金A、B，以及对应指数的相关数据：每日净值、涨幅等等
        temp.muData = csvread(['G:\datastore\母基金1\' muName,'.csv']);
        temp.fjAData = csvread(['G:\datastore\日线1\' fjAName  '.csv']);
        temp.fjBData = csvread(['G:\datastore\日线1\' fjBName  '.csv']);
        temp.zsData = csvread(['G:\datastore\日线1\' zsName  '.csv']);
        temp.name = muCode;  
        temp.slipRate = 0.01;    %
        temp.aShare = str2double(cell2mat( config{statList.aShare}(k) ))/10;   
        temp.bShare = str2double(cell2mat( config{statList.bShare}(k) ))/10;   
        temp.applyFee = str2double(cell2mat( config{statList.applyFee}(k) ));     
        temp.redeemFee = str2double(cell2mat( config{statList.redeemFee}(k) ));  
        temp.stockFee = 0.00025;    % 固定的
        temp.YjThresholds = temp.applyFee + 0.002;
        temp.ZjThresholds = -temp.redeemFee -0.002;
        Src(k) = {temp};
    catch ME
        disp([ME.message ' ' muName]);
        continue ;
    end
 
end
% 清除空cell
emptyCell = cellfun( @isempty, Src ) ;
Src(emptyCell) = [];
srclen = size(Src,2);

if( selectMode == 1 )
    if srclen~=length( selectFund )
     error('有的基金数据不存在');
    end
end
%%
srclen = size(Src,2);
% 按年计算
for year = bgtyear:edtyear
    bgt = getIntDay([year, 1, 1]);
    edt = getIntDay([year, 12, 31]);
    assetManager2 = AssetManager2(handleRate(1), handleRate(2));%2/3持仓
    Result=zeros(1,resultTable.numOfInstance);  % Result每一行记录了每一个交易日的总体折溢盈亏状况， 这里初始化第一行。
    
    resDetial = zeros( rDetialTable.numOfInstance,1,srclen+1 ); % resDetial( :, i, j) 记录了第i个交易日第j个基金品种的信息（折溢率等等，详情见结构体 rDetialtable,由第一个索引指定）, 这里预先分配内存。

    ResultRowCnt = 2;                %Result 表格的行计数器 从第二行开始
    zsHsBgt = 0;
    zsHsClose = 0;
    RateRow = 0;
    %按日计算
    for date = bgt+1:edt %%确保取到昨日净值
        disEDay=[];     %溢价的日期  优先溢价（避免现金不够做折价），折价时先保存，最后排序后选择最大的做
        yjEDay=[];      %折价的日期   
        dailyRes = zeros( 1, resultTable.numOfInstance );   %每天的结果，就是Result中的一行
        isTrade = 0;
        RateRow = RateRow+1;
        resDetial(:,RateRow, rateTable.date ) = date;
        
        %处理每一个种类的基金
        for i = 1:srclen;
            indexMu = find( Src{i}.muData(:,muDailyTable.date)==date);   
            indexFjA = find( Src{i}.fjAData(:,fjDailyTable.date)==date);
            indexFjB = find( Src{i}.fjBData(:,fjDailyTable.date)==date);
            indexZs = find( Src{i}.zsData(:,idxDailyTable.date)==date);
            indexHs = find( zsHs300(:,idxDailyTable.date)==date);  
            if isempty(indexMu) || isempty(indexFjA) || isempty(indexZs) || isempty(indexFjB) || isempty(indexHs)
               continue;
            end
            if indexMu <= 1 || indexFjA <= 1 || indexFjB <= 1 || indexZs <= 1 || indexHs <= 1
                continue;
            end
            
             % 设置局部变量           
            muData = Src{i}.muData( indexMu , : );          %当天母基金数据
            prev_muData = Src{i}.muData( indexMu-1 , : );    %前一天数据
            
            fjAData = Src{i}.fjAData( indexFjA , : );
            prev_fjAData = Src{i}.fjAData( indexFjA-1 , : );
            
            fjBData = Src{i}.fjBData( indexFjB, : );
            prev_fjBData = Src{i}.fjBData( indexFjB-1 , : );
            
            zsData = Src{i}.zsData( indexZs, : );
            
            
            if muData(muDailyTable.netValue) == 0
                continue;
            end
            isNew = assetManager2.find(Src{i}.name);
            if isNew == -1
                assetManager2.addTypes(Src{i}.name);
            end
            zsHsClose  = zsHs300(indexHs, 2);
            if zsHsBgt == 0
                zsHsBgt = zsHsClose;
            end
            if isequal(Src{i}.fjBData(indexFjB,2),Src{i}.fjBData(indexFjB,3),Src{i}.fjBData(indexFjB,4),Src{i}.fjBData(indexFjB,5))%？？为什么要这样
               continue;  
            end
            isTrade = 1;    %判断是交易日
            %计算实际折价率
              %预测当日净值
            predictNetValue = prev_muData(muDailyTable.netValue)*(1+0.95*Src{i}.zsData(indexZs,3)/100);
            %当天折价率，用当天收盘价来估算
            disRate = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare - predictNetValue)/predictNetValue;
            
            % 前一天的净值信息
            openPriceM = prev_muData(muDailyTable.netValue);
            openPriceA = prev_fjAData(fjDailyTable.closingPrice);
            openPriceB = prev_fjBData(fjDailyTable.closingPrice);
            % 当天的净值信息
            closePriceM = muData(muDailyTable.netValue);
            closePriceA = fjAData(fjDailyTable.closingPrice);
            closePriceB = fjBData(fjDailyTable.closingPrice);
            changeM = closePriceM/openPriceM - 1;
            
            if closePriceM == 1 %上下折
                if  changeM > 0.12
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' 下折']);
                    continue;
                elseif changeM < -0.12
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' 上折']);
                    continue;
                end
            end
            changeA = closePriceA/openPriceA - 1;
            changeB = closePriceB/openPriceB - 1;

            if disRate > 0 %溢价先存起来

                pre.rate = disRate;
                pre.pos = i;
                pre.cost = muData(muDailyTable.netValue)*(1+Src{i}.applyFee);
                pre.sy = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare)*(1-Src{i}.stockFee-Src{i}.slipRate*slipRatio);
                % 收益的计算，由卖出子基金A，B获得： sy = （子基金A，B总市值）*（1-股票交易手续费-滑点率*滑点比率）
                % ！！！！！！！！！！！滑点率不应该提现在母基金上吗？
                pre.syRate = (pre.sy-pre.cost)/pre.cost * assetManager2.CcRate();
                
                if changeA < -0.0995 || changeB < -0.0995
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' A或B跌停']);
                    if changeA < -0.0995
                        resDetial( rDetialTable.TradeLimit, RateRow, rateTable.date+i) = pre.syRate;
                    end
                    if changeB < -0.0995
                        resDetial( rDetialTable.TradeLimit, RateRow, rateTable.date+i) = pre.syRate;
                    end
                    
                    continue;
                end               
                yjEDay = [yjEDay pre];
                resDetial( rDetialTable.ZYRate , RateRow, rateTable.date+i) = disRate;      %只要溢价就存ZYRate
                if disRate > Src{i}.YjThresholds
                    resDetial( rDetialTable.YjRate , RateRow, rateTable.date+i) = disRate;  %只有大于阈值，可套利才存YjRate
                end
            elseif disRate < Src{i}.ZjThresholds  %折价先保存，排序后再做
                if changeA > 0.0995 || changeB > 0.0995
                    disp([num2str(date) ' ' num2str(Src{i}.name) ' A或B涨停']);
                    continue;
                end
                dis.rate = disRate;
                dis.rate_mins_thr = dis.rate - Src{i}.ZjThresholds;
                dis.pos = i;
                dis.cost = (fjAData(fjDailyTable.closingPrice)*Src{i}.aShare+fjBData(fjDailyTable.closingPrice)*Src{i}.bShare)*(1+Src{i}.stockFee+Src{i}.slipRate*slipRatio);
                dis.sy = muData(muDailyTable.netValue)*(1-Src{i}.redeemFee);
                dis.syRate = (dis.sy-dis.cost)/dis.cost * assetManager2.CcRate();
                disEDay = [disEDay dis];
                resDetial( rDetialTable.ZYRate , RateRow, rateTable.date+i) = disRate;      %只有大于阈值，可套利才存ZYRate
                resDetial( rDetialTable.ZjRate , RateRow, rateTable.date+i) = disRate;
            else
                continue;
            end
        end

        if isTrade ~= 1 %有数据则表明是交易日,不是交易日则跳过
            RateRow = RateRow - 1;
            continue;
        end
        
        if( date == 41904 )
            ppp = 1;
        end
        
        if ~isempty(yjEDay)
            for j = 1:size(yjEDay,2);
                item = yjEDay(j);
                isOk = assetManager2.canDoYj(Src{item.pos}.name);
                if isOk == 2    % 溢价是基本都可以做的，唯一不可以做的情况是没有子基金A,B的持仓（前一天为了做二倍折价而多合并了母基金）
                    if item.rate > 0% 其实这个条件判断是多余的，因为 yjEDay里的肯定是溢价的
                        disp(['split ' num2str(Src{item.pos}.name)]);
                        assetManager2.doSpl(Src{item.pos}.name);    % 溢价情况下，多了母基金，则要拆分。
                        resDetial( rDetialTable.FHRate , RateRow, rateTable.date+item.pos) = item.rate;
                        resDetial( rDetialTable.FcRate , RateRow, rateTable.date+item.pos) = item.rate;
                    end
                    if item.rate > Src{item.pos}.YjThresholds      
                        dailyRes( resultTable.yjRateLeft ) = dailyRes( resultTable.yjRateLeft ) + item.syRate;  % 超出阈值，可以做溢价套利，但是没有子基金而不能操作，溢价剩余收益累加加。
                        
                    end
                elseif isOk == 1 && item.rate > Src{item.pos}.YjThresholds  
                    assetManager2.doYj(Src{item.pos}.name);  %%！！TODO更新实时操作而导致资产状态变化
                    dailyRes( resultTable.yjNum ) = dailyRes( resultTable.yjNum )+1;
                    dailyRes( resultTable.yjRate ) = dailyRes( resultTable.yjRate ) + item.syRate;        % 套利率累加
                    resDetial( rDetialTable.YjSyRate , RateRow, rateTable.date+item.pos) = item.syRate;
                end
            end
        end

        if ~isempty(disEDay)    %有折价可以做
            % 排序，默认按syRate的升序
            [ascendRate, idx] = sort([disEDay.rate_mins_thr]);
            disEDay = disEDay(idx);
            
            for j = 1:size(disEDay,2);  %不做阈值判断？
                item = disEDay(j);
                isOk = assetManager2.canDoZj(Src{item.pos}.name);
                if isOk == 2
                    dailyRes( resultTable.zjRatePlus ) = dailyRes( resultTable.zjRatePlus ) + item.syRate;  % 指二倍折价策略比一倍折价策略多出的收益？
                end
                if isOk > 0    %判断是否可以作zhe价操作 1或者2
                    zjNum = isOk;   
                    % 两倍折价
                    if zjType == 2
                        if isOk == 1 && item.rate < -0.01   
                            zjNum = 2;
                            resDetial( rDetialTable.FHRate , RateRow, rateTable.date+item.pos) = item.rate;
                            resDetial( rDetialTable.HbRate , RateRow, rateTable.date+item.pos) = item.rate;
                        end
                    end
                    
                    assetManager2.doZj(Src{item.pos}.name, zjNum);  % zjNum == 2 不表示可以做2倍折价，而是该折价操作后，T+1天拥有2倍持仓
                    dailyRes( resultTable.zjNum ) = dailyRes( resultTable.zjNum )+1;
                    dailyRes( resultTable.zjRate ) = dailyRes( resultTable.zjRate ) + item.syRate*isOk;
                    resDetial( rDetialTable.ZjSyRate , RateRow, rateTable.date+item.pos) = item.syRate*isOk;
                elseif isOk < 0   % 现金不够，不能做折价
                    dailyRes( resultTable.nomoneyNum ) = dailyRes( resultTable.nomoneyNum ) + 1;
                    dailyRes( resultTable.zjRateLeft ) = dailyRes( resultTable.zjRateLeft ) - item.syRate*isOk;
                    resDetial( rDetialTable.ZjKsRate , RateRow, rateTable.date+item.pos) = -1;  %表示现金不够不能做折价。
                else        % isOK == 0;
                    resDetial( rDetialTable.ZjKsRate , RateRow, rateTable.date+item.pos) = item.syRate;
                    dailyRes( resultTable.zjRateFail ) = dailyRes( resultTable.zjRateFail ) + item.syRate;
                end
            end
        end

        dailyRes(resultTable.date) = date;
        dailyRes(resultTable.zsRate) = zsHsClose / zsHsBgt; 
        dailyRes(resultTable.vilidVar) = assetManager2.typeNums;
        dailyRes(resultTable.validMoney) = assetManager2.validMoney;
        dailyRes(resultTable.regVar) = dailyRes(resultTable.regVar)/assetManager2.typeNums;            %必须每天标准化
        
        Result(ResultRowCnt,:) = dailyRes;
        Result(ResultRowCnt,resultTable.cumVar ) = Result(ResultRowCnt-1,resultTable.cumVar )+Result(ResultRowCnt,resultTable.cumVar );       
        ResultRowCnt= ResultRowCnt+1;
        
        assetManager2.updateState();      %每日交易结束，模拟证券公司操作，更新资产状态
    end    
    Result(:,resultTable.tlRate) = Result(:,resultTable.yjRate) + Result(:,resultTable.zjRate); %totalTlRate = yjRate + zjRate; 总的套利率等于溢价套利率加上折价套利率 
    Result(:,resultTable.opNum) = Result(:,resultTable.yjNum) + Result(:,resultTable.zjNum);    %opNum = yjNums + zjNums;       总的套利次数等于溢价套利次数加上折价套利次数
    Result(1,:) = []; %删除第一行

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tradeDays = size(Result,1);
    timesDuration = Result(end,1)-bgt+1;
    result = Result(end,:)*100; 
    %日均率计算
    resultD = result;    
    resultD(resultTable.transVar) = resultD(resultTable.transVar)/tradeDays;
    %年化率计算
    resultY = result; 
    resultY(resultTable.transVar) = resultY(resultTable.transVar)/timesDuration*365;
 
    typeNumsM = mean(Result(:,resultTable.vilidVar));
    figure1=figure();
    % subplot(211);
    hold on;
    x = Result(:,1)+693960;
    y = Result(:,resultTable.tlRate);
    plot(x,y+1, 'r');
    datetick('x',28);
    xmin = min(x);
    xmax = max(x);
    ymin = 0.5;
    ymax = 2.5;
    axis([xmin xmax ymin ymax]);
    if zjType == 2
        fTitle = '两倍折价';
    else
        fTitle = '一倍折价';
    end
    title(fTitle);
    inner = (ymax-ymin)/10;
    text(xmin+10,ymax-inner*1,['开始时间：',datestr(Result(1,resultTable.date)+693960,'yyyy-mm-dd'),'    ','结束时间：',datestr(Result(end,resultTable.date)+693960,'yyyy-mm-dd')],'FontSize',10);
    text(xmin+10,ymax-inner*2,['实际交易日：' num2str(tradeDays) '天      输入时间跨度：' num2str(timesDuration) '天    持仓品种数均值：' num2str(typeNumsM)],'FontSize',10);
    text(xmin+10,ymax-inner*3,['总收益率：' num2str(result(resultTable.tlRate)) '%    年化收益率：' num2str(resultY(resultTable.tlRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.tlRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*4,['折价总收益率：' num2str(result(resultTable.zjRate)) '%    折价年化收益率：' num2str(resultY(resultTable.zjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.zjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*5,['溢价总收益率：' num2str(result(resultTable.yjRate)) '%    溢价年化收益率：' num2str(resultY(resultTable.yjRate)) '%' '    平均每天套利：' num2str(resultD(resultTable.yjRate)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*6,['折价额外总收益率：' num2str(result(resultTable.zjRatePlus)) '%    折价额外年化收益率：' num2str(resultY(resultTable.zjRatePlus)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*7,['折价剩余总收益率：' num2str(result(resultTable.zjRateLeft)) '%    折价剩余年化收益率：' num2str(resultY(resultTable.zjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*8,['溢价剩余总收益率：' num2str(result(resultTable.yjRateLeft)) '%    溢价剩余年化收益率：' num2str(resultY(resultTable.yjRateLeft)) '%'],'FontSize',10);
    text(xmin+10,ymax-inner*9,['溢价浪费总收益率：' num2str(result(resultTable.zjRateFail)) '%    溢价浪费年化收益率：' num2str(resultY(resultTable.zjRateFail)) '%'],'FontSize',10);
    plot(x,Result(:,resultTable.zsRate),'g');
    plot(x,Result(:,resultTable.tlRate) + Result(:,resultTable.zsRate),'b');
    plot(x,Result(:,resultTable.zjRateLeft)+1,'k');
    plot(x,Result(:,resultTable.zjRatePlus)+1,'y');
    plot(x,Result(:,resultTable.yjRateLeft)+1,'c');
    legend('套利净值', '沪深300', '资金总净值', '折价套利剩余空间', '二倍折价额外收益', '二倍折价溢价减益', -1);


    configFile = 'config';
    saveDir = ['..\result\折溢价率\' configFile '_' num2str(slipRatio) '倍滑点_持仓比' num2str(handleRate(1)) '-' num2str(handleRate(2))];
    if exist(saveDir,'dir') == 0
        mkdir(saveDir);
    end
    figurePath = [saveDir '\' fTitle '_' num2str(year) '.bmp'];
    set(gcf,'outerposition',get(0,'screensize'));
    saveas( gcf, figurePath );
    %RD = resDetial( rDetialTable.ZYRate,:,:);
    %RD = squeeze(RD);
    csvwrite([saveDir '\' num2str(year) 'Result.csv'], Result );
    csvwrite([saveDir '\' num2str(year) '折溢价率.csv'], squeeze(resDetial( rDetialTable.ZYRate,:,:)) );
    csvwrite([saveDir '\' num2str(year) '折价率.csv'], squeeze(resDetial( rDetialTable.ZjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '溢价率.csv'], squeeze(resDetial( rDetialTable.YjRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '折价收益率.csv'], squeeze(resDetial( rDetialTable.ZjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '折价亏损率.csv'], squeeze(resDetial( rDetialTable.ZjKsRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '溢价收益率.csv'], squeeze(resDetial( rDetialTable.YjSyRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '分拆合并折溢价率.csv'], squeeze(resDetial( rDetialTable.FHRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '分拆溢价率.csv'], squeeze(resDetial( rDetialTable.FcRate,:,:)));
    csvwrite([saveDir '\' num2str(year) '合并折价率.csv'], squeeze(resDetial( rDetialTable.HbRate,:,:)));

end
end