function [x,x_rho,x_change] = MRAS(cover_name, original_img, attack_name, rho_mode, simflag, cover_q, attack_q, shuffle_seed, len)
C_Struct = jpeg_read(cover_name);
coefs = C_Struct.coef_arrays{1};
quant = C_Struct.quant_tables{1};

oimg = imread(original_img);
dcts = blkproc(double(oimg)-128, [8,8], 'dct2');

fun = @(x) x./quant;
qdcts = blkproc(dcts, [8,8], fun);

diff = qdcts - coefs;
diff(diff < -0.5) = -0.5;
diff(diff > 0.5) = 0.5;

%% 计算失真（1-UERD，2-GUED，3-J-UNIWARD）
if rho_mode == 1
    [rhoM1,rhoP1] = uerd(cover_name);
elseif rho_mode == 2
    [rhoM1,rhoP1] = GUED_J(cover_name, cover_q);
else
    %[rhoM1,rhoP1] = J_UNIWARD_D(cover_name,1);
    i_img = cover_name(11:end);
    i_img = split(i_img,'.');
    i_img = str2double(i_img{1});
    rho=load(['.\rho', num2str(cover_q), '\', num2str(i_img),'.mat']);
    rhoP1=rho.var;
end

%% 残差信息--调整失真
%     rhoP1(rhoM1 == 10^10) = 10^10;
% SI_rho = rhoP1 .* (1 - 2*abs(diff));
SI_rho = rhoP1;
change = sign(diff);
rand_change = round(rand(length(find(change==0)),1));
rand_change(rand_change == 0) = -1;
change(change == 0) = rand_change;

%% 提取载体元素
x = zeros(4096 * 9, 1);
x_change = zeros(4096 * 9, 1);
x_rho = zeros(4096 * 9, 1);

n_lsb = 0;
for m = 1:64
    for n = 1:64
        for i = 1:8
            for j = 1:8
                if (i+j==5)||(i+j==6)%中频9个DCT系数
                    n_lsb = n_lsb + 1;
                    coef = coefs((m-1)*8+i,(n-1)*8+j);
                    x_change(n_lsb) = change((m-1)*8+i,(n-1)*8+j);
                    x_rho(n_lsb) = SI_rho((m-1)*8+i,(n-1)*8+j);
                    if mod(coef,2) == 1
                        x(n_lsb) = 1;
                    end
                end
            end
        end
    end
end

%% 模拟嵌入 -- 设置湿点
if simflag
    rng(shuffle_seed);
    perm = randperm(length(x));
    x_perm = x(perm);
    x_perm(1:len*256*8) = ~x_perm(1:len*256*8);
    y = x;
    y(perm) = x_perm;
    need_change = xor(x,y);
    
    idx = 0;
    for m = 1:64
        for n = 1:64
            for i = 1:8
                for j = 1:8
                    if (i+j==5)||(i+j==6)%中频9个DCT系数
                        idx = idx + 1;
                        if need_change(idx)
                            coefs((m-1)*8+i,(n-1)*8+j) = coefs((m-1)*8+i,(n-1)*8+j) + x_change(idx);
                        end
                    end
                end
            end
        end
    end
    C_Struct.coef_arrays{1} = coefs;
    jpeg_write(C_Struct,attack_name);
    imwrite(imread(attack_name),attack_name,'quality', attack_q);
    acs = jpeg_read(attack_name);
    acoefs = acs.coef_arrays{1};
    ay = zeros(4096 * 9, 1);
    n_lsb = 0;
    for m = 1:64
        for n = 1:64
            for i = 1:8
                for j = 1:8
                    if (i+j==5)||(i+j==6)%中频9个DCT系数
                        n_lsb = n_lsb + 1;
                        acoef = acoefs((m-1)*8+i,(n-1)*8+j);
                        if mod(acoef,2) == 1
                            ay(n_lsb) = 1;
                        end
                    end
                end
            end
        end
    end
    wetpoint = xor(y,ay);
    x_rho(wetpoint==1) = 10^10;
end
end

