clear
clc
cover_num=10000;
cover_dir='./Cover85';
rho_dir ='./rho85';if ~exist(rho_dir,'dir'); mkdir(rho_dir); end
parfor i_img=1:cover_num
% for i_img=1:cover_num
    disp(i_img);
    cover_path = fullfile([cover_dir,'\',num2str(i_img),'.jpg']);
    [rho] = J_UNIWARD_D(cover_path,1);
    parsave([rho_dir,'/',num2str(i_img),'.mat'],rho);
end

function parsave(filename,var)
save(filename,'var');
end