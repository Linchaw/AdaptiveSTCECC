function MRAS_em(cover_name,stego_name, x,x_rho,x_change, msg, len, attack_q, h, ts, shuffle_seed)
[y] = embed_x2y(x,x_rho,msg, len, h, shuffle_seed);
    function [y] = embed_x2y(x, x_rho, msg, len, h, shuffle_seed)
        rng(shuffle_seed);
        perm = randperm(length(x));
        x_perm = uint8(x(perm));
        rho_perm = x_rho(perm);
        [~, stc_msg] = stc_embed(x_perm(1:192*8*len), msg, rho_perm(1:192*8*len), h);
        [check_code, ~] = rs_encode_crc(stc_msg,192*8*len,200,192);
        [~, stc_msg_check] = stc_embed(x_perm(192*8*len+1:256*8*len), check_code, rho_perm(192*8*len+1:256*8*len), h);
        x_perm(1:192*8*len) = stc_msg;
        x_perm(192*8*len+1:256*8*len) = stc_msg_check;
        y = x;
        y(perm) = x_perm;
    end
need_change = xor(x,y);

cs = jpeg_read(cover_name);
coef = cs.coef_arrays{1};
[row,col] = size(coef);
idx = 0;
for m = 1:row/8
    for n = 1:col/8
        for i = 1:8
            for j = 1:8
                if (i+j==5)||(i+j==6)%中频9个DCT系数
                    idx = idx + 1;
                    if need_change(idx)
                        coef((m-1)*8+i,(n-1)*8+j) = coef((m-1)*8+i,(n-1)*8+j) + x_change(idx);
                    end
                end
            end
        end
    end
end
cs.coef_arrays{1} = coef;
jpeg_write(cs, stego_name);

% 减少多个通道之间的对嵌入相互影响
for times = 1:ts
    imwrite(imread(stego_name),stego_name, 'quality', attack_q)
    acs = jpeg_read(stego_name);
    acoef = acs.coef_arrays{1};
    idx = 0;
    ay = y;
    for m = 1:64
        for n = 1:64
            for i = 1:8
                for j = 1:8
                    if (i+j==5)||(i+j==6)%中频9个DCT系数
                        idx = idx + 1;
                        c = acoef((m-1)*8+i,(n-1)*8+j);
                        if mod(c,2) == 1
                            ay(idx) = 1;
                        else
                            ay(idx) = 0;
                        end
                        if y(idx) ~= ay(idx)
                            if times == 1
                                acoef((m-1)*8+i,(n-1)*8+j) = coef((m-1)*8+i,(n-1)*8+j);
                            else
                                tmpchange = round(rand(1))*2 - 1;
                                acoef((m-1)*8+i,(n-1)*8+j) = acoef((m-1)*8+i,(n-1)*8+j) + tmpchange;
                            end
                        end
                    end
                end
            end
            
        end
    end
acs.coef_arrays{1} = acoef;
jpeg_write(acs, stego_name);
end

% RS encode
function [check_code, check_code_len] = rs_encode_crc(raw_msg,raw_msg_len,n,k)
m  = 8; % 不变
fill_len = ceil(raw_msg_len / (m*k))*(m*k);
fill_msg = padarray(raw_msg, fill_len - raw_msg_len, 0, 'post');
mat_msg = reshape(fill_msg,[],m);
str = string(mat_msg);
binstr = strings(fill_len/m,1);
dec_msg = uint32(zeros(fill_len/m,1));
for i = 1:fill_len/8
    binstr(i) = strcat(str(i,1),str(i,2),str(i,3),str(i,4),str(i,5),str(i,6),str(i,7),str(i,8));
    dec_msg(i) = bin2dec(binstr(i));
end
mat_dec_msg = reshape(dec_msg, [], k);
msg_gf = gf(mat_dec_msg,m);
code = rsenc(msg_gf,n,k);
rs_mat_msg = code.x;

check_dec_code = reshape(rs_mat_msg(:,k+1:end),[],1);
check_binstr_code = dec2bin(check_dec_code);
check_bin_code = reshape(check_binstr_code,[],1);
check_code = uint8(str2num(check_bin_code));
check_code_len = length(check_code);
end

end

