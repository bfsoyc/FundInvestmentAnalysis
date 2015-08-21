%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 交易的母基金及分级A、B的量必须是整百,故对一个任意的交易量 tradeVol（母基金），
% 需要向下调整到能够交易的量.目前只支持3种A、B的比例
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tradeVol = adjustVol( tradeVol, aShare, bShare )
    if aShare*5 == bShare*5   % 5:5
        M = mod( tradeVol,200 );
        tradeVol = tradeVol - M;
    elseif aShare*4 == bShare*6  % 6:4
        M = mod( tradeVol,500 );
        tradeVol = tradeVol - M;
    elseif aShare*3 == bShare*7  % 7:3
        M = mod( tradeVol,1000 );
        tradeVol = tradeVol - M;
    else
        error('未知比例,或检查精度问题');
    end
end