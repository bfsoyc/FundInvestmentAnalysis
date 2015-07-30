function [C] = list2str(list)
C = num2str(list(1, 1));
num = size(list, 2);
for i = 2:num
    C = [C '.' num2str(list(1, i))];
end
end