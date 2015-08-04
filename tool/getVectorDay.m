% 日期转换公式
function [Y M D] = getVectorDay(day)
[Y M D] = datevec(day + 693960);
end