function [ value ] = getPreValue( lastValue, change )
    value = lastValue*(1+change*0.95/100);
end

