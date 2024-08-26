function [qtable] = getqtable(quality)
%GETQTABLE 根据量化因子获取量化表
%   此处显示详细说明
    table = [16,11,10,16,24,40,51,61;
            12,12,14,19,26,58,60,55;
            14,13,16,24,40,57,69,56;
            14,17,22,29,51,87,80,62;
            18,22,37,56,68,109,103,77;
            24,35,55,64,81,104,113,92;
            49,64,78,87,103,121,120,101;
            72,92,95,98,112,100,103,99];
        
     if (quality <= 0)
         quality = 1;
     elseif(quality>100)
         quality = 100;
     end
     
     if (quality < 50)
        quality = 5000 / quality;
     else
         quality = 200 - quality * 2;
     end
     
     qtable = zeros(8,'uint8');
     for i = 1:8
         for j = 1:8
             qtable(i,j) = max(1,min(255,floor((table(i,j)*quality+50)/100)));
         end
     end
    
     qtable = double(qtable);
end

