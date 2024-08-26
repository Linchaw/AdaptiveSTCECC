clc; clear; close all; fclose all;
rng('default') % 恢复默认随机数设置，避免使用旧随机数函数后，产生报错 

%% * 初始化设置*
Bossbase_path = '../BOSSbase_1.01';   % 只需填入图像数据集路径即可
rng(1);
Emsg = uint8(round(rand(150000,1))); % 在调试时，可以直接做提取操作，检查错误位置，省事  可删除

%% ==========================================================================================================%
%% Réglages des paramètres
h = 10;
rho_mode = 3;% 1 - UERD  2 - GUED  3 - J_Uniward
cover_q = 75;
attack_q = 75;
test_num = 2000;
w = 4; 
shuffle_seed = 11;
Error_ALL = zeros(10,1);
Error_mat = cell(10,1);
Perfect_ex = zeros(10,1);
tmp = 0;
for payload = 0.4:0.01:0.4
%for payload = 0.01:0.01:0.1
% payload = 0.08;
Error_ratio = zeros(test_num, 1);
cover_path = ['./Cover',num2str(cover_q)];  if ~exist(cover_path, 'dir') mkdir(cover_path); end
stego_path = ['./Stego',num2str(cover_q), '_', num2str(payload)]; if ~exist(stego_path, 'dir') mkdir(stego_path); end
attack_path = './Attack'; if ~exist(attack_path, 'dir') mkdir(attack_path);end
%% ==========================================================================================================%
%% 消息嵌入与提取
perfect_ex = 0;
% parfor idx = 1:test_num
for idx = 1:test_num
    idx_name = idx;
    %% 隐写图片路径设置
    boss_img_name = [Bossbase_path '/' num2str(idx_name) '.pgm'];
    cover_name = [cover_path '/' num2str(idx_name) '.jpg'];
    stego_name = [stego_path '/' num2str(idx_name) '.jpg'];
    attack_name = [attack_path '/' num2str(idx_name)  '.jpg'];
    Stable_Compression(boss_img_name,cover_name,cover_q, 15);
%     continue;
    
    %% 秘密信息生成
    cs = jpeg_read(cover_name);
    coef = cs.coef_arrays{1};
    nzAC = nnz(coef) - nnz(coef(1:8:end,1:8:end));
    msg_len = ceil(payload*nzAC);
    
    if msg_len <= 16 % 2-Bytes以下不太适合嵌入
        perfect_ex = perfect_ex + 1;
        imwrite(imread(cover_name),stego_name,'quality',attack_q);
        continue
    end
    
%     msg = uint8(round(rand(msg_len,1)));
    msg = Emsg(1:msg_len);
    
    %% 自适应载体选择
    len = min(ceil(msg_len * w / 8 / 192),18);
%     len = 18;
    
    %% 嵌入失真计算
    [x,x_rho,x_change] = MRAS(cover_name, boss_img_name, attack_name, rho_mode, 1, cover_q, attack_q, shuffle_seed, len);
    
    %% 嵌入秘密信息
    MRAS_em(cover_name,stego_name, x,x_rho,x_change, msg, len, attack_q, h, 5, shuffle_seed)
%     MRAS_ems(cover_name,stego_name, x,x_rho,x_change, msg, len, attack_q, h, 3, shuffle_seed)

    %% 模拟信道攻击
    imwrite(imread(stego_name),attack_name,'quality',attack_q);
    
    %% 提取秘密信息
    [emsg] = MRAS_ex(attack_name, msg_len, len, cover_q, h, shuffle_seed);
%     [emsg] = MRAS_exs(attack_name, msg_len, len, cover_q, h, shuffle_seed);
    
    %% 提取错误率
    e = double(emsg) - double(msg);
    Error_ratio(idx) = nnz(e)/ msg_len;
    if Error_ratio(idx) == 0
            perfect_ex = perfect_ex + 1;
    else
            fprintf('%s\n',['No.: ',num2str(idx),'  payload: ',num2str(payload),'  image_number: ',num2str(idx_name),...
         '  msg_len: ',num2str(msg_len), ' error_rate: ',num2str(Error_ratio(idx))]);  
    end
    fprintf('%s\n',['No.: ',num2str(idx),'  payload: ',num2str(payload),'  image_number: ',num2str(idx_name),...
         '  msg_len: ',num2str(msg_len), ' error_rate: ',num2str(Error_ratio(idx))]); 
end
tmp = tmp + 1;
Perfect_ex(tmp) = perfect_ex;
Error_ALL(tmp)= sum(Error_ratio(:)) / test_num;
Error_mat{tmp} = Error_ratio;
disp( sum(Error_ratio(:)) / test_num);
end

%% ==========================================================================================================%
function Stable_Compression(original_cover_name,cover_name,img_q, times)
    imwrite(imread(original_cover_name),cover_name,'quality',img_q);    
    cs = jpeg_read(cover_name);
    coef = cs.coef_arrays{1};
    
    while times
        imwrite(imread(cover_name),cover_name,'quality',img_q);
        tcs = jpeg_read(cover_name);
        tcoef = tcs.coef_arrays{1};
        e = (coef~=tcoef);
        error = sum(e(:));
        if error == 0
            break
        end
        times = times - 1;
        coef = tcoef;
    end
end
