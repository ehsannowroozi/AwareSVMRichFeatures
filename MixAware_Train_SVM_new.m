% Script for training the MIXAware-SVM (i.e., both double and attacked in the negative class) and test it
% Case of binary classification 

% The MIXAware-SVM is a generalization of the EUSIPCO paper where several QF2 are considered in the training mixture.

clc
clear all

% Add JPEG TOOLBOX
addpath(genpath('./jpeg_readwrite'));

% Add LIBSVM package
addpath(genpath('./Libsvm-3.17'));



%%%%%%% load the features corresponding to a given DATASET, QF2 and SIZE e initialize %%%%%%%%%%%%%%%%%

ROOT = 'F:\ImagesJPEG_comp_newData\fromRAISE2K\Features\sub_1_1424x2144\TRAIN\95\';
QF2 =95;
dataset = 'RAISE';
sizeImg = '1424x2144';  %'2848x4288'; % '712x1072';

%%%%%%%%%%%%%% CHOOSE the Attack and QF1s for training %%%%%%%%%%%%

Proc_Type1 = 'Resize'; % 'StammDenoising';
Proc_Param1 = '09'; % here, it must be inputed as a string
Proc_Type2 = 'StammDithering';
Proc_Param2 = '1';


QF1_double= [75, 80,85,90,93,97]; %[65, 70,75,80];% [65,70,75,80,83]; %[80,85,90,97];
QF1_attk= [75, 80,85,90,97]; %,80,83]; %[80,85,90,97];


N = 1700; % number of images 


N_double = N*numel(QF1_double);
N_attk = N*numel(QF1_attk);



%load SINGLE; DOUBLE and ATTACKED FEATURES

nameS = 'feat_single';
nameD = 'feat_double';
nameA1 = ['feat_attacked_' Proc_Type1 '_' Proc_Param1];
nameA2 = ['feat_attacked_' Proc_Type2 '_' Proc_Param2];


name_varS = [nameS '_' num2str(QF2)];
load([ROOT nameS  '.mat'], name_varS);
eval(['data_single =' name_varS ';']);


for i = 1:numel(QF1_double)
    name_varD = [nameD '_' num2str(QF1_double(i)) '_' num2str(QF2)];
    load([ROOT nameD  '.mat'], name_varD);
end


for i = 1:numel(QF1_attk)
    name_varA1 = [nameA1 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];
    name_varA2 = [nameA2 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];

    load([ROOT nameA1  '.mat'], name_varA1);
    load([ROOT nameA2  '.mat'], name_varA2);
end

%eval(['data_attacked =' name_var ';'])


%%%%%%%%%%%%%%% Merge QF1s %%%%%%%%%%%


for i = 1:numel(QF1_double)
    name_varD = [nameD '_' num2str(QF1_double(i)) '_' num2str(QF2)]; 
    eval(['data_double(i:numel(QF1_double): i + N_double - numel(QF1_double), :) =' name_varD ';']); 
end


for i = 1:numel(QF1_attk)
    name_varA1 = [nameA1 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];
    name_varA2 = [nameA2 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];
    eval(['data_attacked1(i:numel(QF1_attk): i + N_attk - numel(QF1_attk), :) =' name_varA1 ';']);
    eval(['data_attacked2(i:numel(QF1_attk): i + N_attk - numel(QF1_attk), :) =' name_varA2 ';']);
end



% Divide in training and N-fold cross validation 

Ncv = 300;
Ntrain = N - Ncv; %1400;


% indexing 
cv_idx_S = 1:Ncv;
cv_idx_D = 1:Ncv*(numel(QF1_double));
cv_idx_A = 1:Ncv*(numel(QF1_attk));
tr_idx_S = Ncv + 1: Ncv + Ntrain;
tr_idx_D = Ncv*(numel(QF1_double)) + 1: N_double; 
tr_idx_A = Ncv*(numel(QF1_attk)) + 1:  N_attk; 



%----------------------------------------------------------------------
% 1. N-fold cross-validation
%----------------------------------------------------------------------

% All 0's for single JPEG, all ones for double JPEG
cross_labels = [zeros(1,numel(cv_idx_S)), ones(1,numel(cv_idx_D)), ones(1,2*numel(cv_idx_A))]';

% Examples for cross-validation
cross_data = [data_single(cv_idx_S,:); data_double(cv_idx_D,:);  data_attacked1(cv_idx_A,:);  data_attacked2(cv_idx_A,:)];



% Grid of parameters
folds = 5;

[C,gamma] = meshgrid(15, -15:2:-9); % fast preliminary test  




% balancing SVM
bal = (size(data_double,1) + size(data_attacked1,1) + size(data_attacked2,1))/(size(data_single,1)); 


% Grid search
cv_acc = zeros(numel(C),1);
for  i=1:numel(C)
    cv_acc(i) = svmtrain(cross_labels, cross_data, ...
        sprintf(['-q -c %f -g %f -v %d  -b 1 -w0 ' num2str(bal) ' -w1 1'], 2^C(i), 2^gamma(i), folds));
       
end


% Pair (C,gamma) with best accuracy
[~,idx] = max(cv_acc);

% % Contour plot of parameter selection
% contour(C, gamma, reshape(cv_acc,size(C))), colorbar
% hold on
% plot(C(idx), gamma(idx), 'rx')
% text(C(idx), gamma(idx), sprintf('Acc = %.2f %%',cv_acc(idx)), ...
%    'HorizontalAlign','left', 'VerticalAlign','top')
% hold off
% xlabel('log_2(C)'), ylabel('log_2(\gamma)'), title('Cross-Validation Accuracy')



%----------------------------------------------------------------------
% 2. Training model using best_C and best_gamma
%----------------------------------------------------------------------

bestc = 2^C(idx);
bestg = 2^gamma(idx);

% Training on images from each class not used in cross-validation
trainLabel = [zeros(1,numel(tr_idx_S)), ones(1, numel(tr_idx_D)), ones(1,2*numel(tr_idx_A))]';
trainData = [data_single(tr_idx_S,:); data_double(tr_idx_D,:);  data_attacked1(tr_idx_A,:); data_attacked2(tr_idx_A,:)];

% Train (probabilistic model)
model = svmtrain(trainLabel, trainData, ['-c ' num2str(bestc) ' -g ' num2str(bestg) ' -b 1' '-w0 ' num2str(bal) ' -w1 1']);
%model = svmtrain(trainLabel, trainData, ['-c ' num2str(bestc) ' -g ' num2str(bestg) ' -b 1']);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


save(['MixAWARE_75-97_' Proc_Type1 num2str(Proc_Param1) '-' Proc_Type2 num2str(Proc_Param2) '_' dataset '_' sizeImg '_' num2str(QF2) 'new.mat'],'model','data_single','data_double', 'data_attacked1', 'data_attacked2',...
    'QF2', 'QF1_double', 'QF1_attk', 'Proc_Type1', 'Proc_Param1', 'Proc_Type2', 'Proc_Param2', 'dataset', 'sizeImg', ...
    'N', 'N_double', 'N_attk', 'Ncv', 'Ntrain',  'cv_idx_S', 'cv_idx_D', 'cv_idx_A', 'tr_idx_S', 'tr_idx_D',  'tr_idx_A',  'bestc', 'bestg', 'cv_acc', 'idx')










