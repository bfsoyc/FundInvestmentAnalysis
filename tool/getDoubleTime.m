% 时间转换公式 hms = [h m s]; return = (h + (m + s / 60) / 60) / 24
function [T] = getDoubleTime(hms)
h = hms(1, 1);
m = hms(1, 2);
s = hms(1, 3);
T = (h + (m + s / 60) / 60) / 24;
end