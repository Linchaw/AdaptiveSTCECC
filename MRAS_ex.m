function [msg] = MRAS_ex(stego_name, raw_msg_len, len, cover_q, h, shuffle_seed)

img = imread(stego_name);
cover_dcts = blkproc(double(img)-128, [8,8], 'dct2');
quant = getqtable(cover_q);
fun = @(x) x./ quant;
coefs = blkproc(cover_dcts, [8,8], fun);
coef = round(coefs);

[row,col] = size(coef);
y = zeros(4096 * 9, 1);
idx = 0;
for m = 1:row/8
    for n = 1:col/8
        for i = 1:8
            for j = 1:8
                if (i+j==5)||(i+j==6)%中频9个DCT系数
                    idx = idx + 1;
                    c = coef((m-1)*8+i,(n-1)*8+j);
                    if mod(c,2) == 1
                        y(idx) = 1;
                    end
                end
            end
        end
    end
end
msg = extract_y2m(uint8(y), raw_msg_len, len, h,shuffle_seed);

    function msg = extract_y2m(y, msg_len, len, h,shuffle_seed)
        rng(shuffle_seed);
        perm = randperm(length(y));
        y_perm = uint8(y(perm));
        stc_extract_Check_code = stc_extract(y_perm(192*8*len+1:256*8*len), len*8*8, h);
        [ecoded_msg_bin] = rs_decode_crc(y_perm(1:192*8*len), stc_extract_Check_code, 200,192);
        msg = stc_extract(ecoded_msg_bin, msg_len, h);
    end

    function [msg] = rs_decode_crc(msg, check_code, n,k)
        m  = 8; % 不变
        
        char_msg = char(msg+48);
        char_check =  char(check_code+48);
        binstr_msg = reshape(char_msg,[],m);
        binstr_check = reshape(char_check,[],m);
        dec_msg = bin2dec(binstr_msg);
        dec_check = bin2dec(binstr_check);
        rs_dec_msg = cat(1,dec_msg,dec_check);
        rs_mat_msg = reshape(rs_dec_msg,[],n);
        rs_mat_msg_gf = gf(rs_mat_msg,m);
        decode = rsdec(rs_mat_msg_gf, n,k);
        decmsg = decode.x;
        dec_msg = reshape(decmsg,[],1);
        binstr_msg = dec2bin(dec_msg);
        bin_msg = reshape(binstr_msg,[],1);
        msg = uint8(str2num(bin_msg));
    end

end

