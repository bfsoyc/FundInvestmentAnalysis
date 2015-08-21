%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ���׵�ĸ���𼰷ּ�A��B��������������,�ʶ�һ������Ľ����� tradeVol��ĸ���𣩣�
% ��Ҫ���µ������ܹ����׵���.Ŀǰֻ֧��3��A��B�ı���
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
        error('δ֪����,���龫������');
    end
end