% ��Reproduce "Fast Upsampling"��
% This is the entrance of the whole project.
% An implementation of "Fast Image Upsampling".

%% Initialize parameters
clear; close all; clc;
UPSAMP.factor = 4;  % magnification factor
UPSAMP.iter = 3;  % times of iteration
DECONV.lambda_1 = 0.01;  % lambda_1
DECONV.lambda_2 = 1;  % lambda_2
DECONV.iter_max =10;  % max deconv iterations
GAU.size = 11;  % size of gaussian kernel
GAU.var = 1;  % variance of gaussian kernel
IMG.name = 'words';
IMG.read = ['images/', IMG.name, '_small.jpg'];

%% Load original image and split channels
% Stuff about image L (input low resolution image).
L = im2double(imread(IMG.read));
L = rgb2gray(L);
L = imbinarize(L);

%% Show image L
% Image L duplicatedly resized to show.
L_show = pixeldup(L, UPSAMP.factor);
close all;
FIG_HANDLE.L = figure('Name', 'IMG - Low Resolution');
movegui(FIG_HANDLE.L, 'west');
imshow(L_show);
title('Original image has been resized to display.');

%% Upsample initially
H_tilde = im2double(imresize(L, UPSAMP.factor, 'bicubic'));

%% Feed-back control loop (**essential step**)
for i = 1:UPSAMP.iter
    %��Normalize��
    [H_tilde_norm, low, gap] = simpnormimg(H_tilde);
    
    %��Non-blind deconvolution��
    H_star = nbDeconv(H_tilde_norm, DECONV, GAU);
    IMG.appro = 'mine';
    IMG.other = [num2str(DECONV.lambda_2), '_lam2'];

%     %��Non-blind deconvolution: Lagrangian approach��
%     kernel = fspecial('gaussian', GAU.size, GAU.var);
%     H_star = fftCGSRaL(H_tilde_norm, kernel);
%     IMG.appro = 'caip';
%     IMG.other = '';

    %��Print and denormalize��
    disp([newline,' ============>��Iteration ',...
    num2str(i), ' done!��',newline]);
    H_star = H_star*gap + low;
    
    if(i == UPSAMP.iter),break;end
    
    %��Reconvolution��
    PSF = fspecial('gaussian', 3, 1);
    H_s = imfilter(H_star, PSF, 'same', 'conv');
    
    %��Pixel substitution��
    H_tilde = H_s;
    H_tilde(1:UPSAMP.factor:end,...
            1:UPSAMP.factor:end) = L(:,:);
end

%% Show and save result
FIG_HANDLE.H = figure('Name', 'IMG - High Resolution');
movegui(FIG_HANDLE.H, 'east');
figure(FIG_HANDLE.H);
imshow(H_star);
title(['After ', num2str(i), ' iterations']);

mkdir(['results/', IMG.name]);
IMG.write = ['results/', IMG.name, '/',...
    [IMG.name, '_', IMG.appro,],...
    ['_', num2str(UPSAMP.factor), 'x'],...
    ['_', num2str(UPSAMP.iter), '_iter'],...
    ['_', num2str(GAU.size),'-', num2str(GAU.var), '_gau'],...
    ['_', IMG.other],...
    '.jpg'];
imwrite(H_star, IMG.write);
disp([newline,' ============>��Image "',...
    IMG.write, '" saved!��',newline]);

%% Function on call
function [I, low, gap] = simpnormimg(G)

lb = min(G(:));
ub = max(G(:));

gap = ub-lb;
low = lb;
I = (G - low) ./ gap;
end
   