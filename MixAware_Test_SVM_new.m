

%--------------------------------------------------------------------------
%                          Testing (to be launched after the Training)
%--------------------------------------------------------------------------

% Global testing with the same attacks and QF1s used for training

clc
clear all

% % load the model

name = 'MixAWARE_65-80_Resize09-StammDithering1_RAISE_2848x4288_85new.mat';

load(name);

% Note: The QF2 value is written inside


% path of the to be tested samples

ROOT = 'F:\ImagesJPEG_comp_newData\fromRAISE2K\Features\sub_0_2848x4288\TEST\85\';



Ntest = 300; % number of images for testing (single)
Ntest_double = Ntest*numel(QF1_double);
Ntest_attk = Ntest*numel(QF1_attk);



%load SINGLE; DOUBLE and ATTACKED FEATURES
nameS = 'feat_single';
nameD = 'feat_double';
nameA1 = ['feat_attacked_' Proc_Type1 '_' Proc_Param1];
nameA2 = ['feat_attacked_' Proc_Type2 '_' Proc_Param2];


name_varS = [nameS '_' num2str(QF2)];
load([ROOT nameS  '.mat'], name_varS);
eval(['data_single_T = ' name_varS ';']); %?????eval


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



% Merge QF1s

for i = 1:numel(QF1_double)
    name_varD = [nameD '_' num2str(QF1_double(i)) '_' num2str(QF2)]; 
    eval(['data_double_T(i:numel(QF1_double): i + Ntest_double - numel(QF1_double), :) =' name_varD ';']); 
end


for i = 1:numel(QF1_attk)
    name_varA1 = [nameA1 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];
    name_varA2 = [nameA2 '_' num2str(QF1_attk(i)) '_' num2str(QF2)];
    eval(['data_attacked1_T(i:numel(QF1_attk): i + Ntest_attk  - numel(QF1_attk), :) =' name_varA1 ';']);
    eval(['data_attacked2_T(i:numel(QF1_attk): i + Ntest_attk  - numel(QF1_attk), :) =' name_varA2 ';']);
end



% TESTING

% Clean training data
testLabel = [zeros(1,Ntest), ones(1,Ntest_double), ones(1,2*Ntest_attk)]';
testData = [data_single_T; data_double_T; data_attacked1_T; data_attacked2_T];


% Test
[predict_label, accuracy, prob_values] = svmpredict(testLabel, testData, model, ' -b 1');



%--------------------------------------------------------------------------
% ROC curves and AUC
%--------------------------------------------------------------------------

steps = linspace(0, 1, 1000);

FP = zeros(1,numel(steps)); 
ATN = zeros(1,numel(steps));
TN = zeros(1,numel(steps));
TN_attack = zeros(1,numel(steps));



for l=1:numel(steps)
    TN(l) = sum(prob_values(Ntest+1:Ntest + Ntest_double,2)>steps(l))/Ntest_double; % fraction of DC correctly classified
    TN_attack(l) = sum(prob_values(Ntest+ Ntest_double + 1:Ntest + Ntest_double + 2*Ntest_attk,2)>steps(l))/(2*Ntest_attk); % fraction of attacked correctly classified
    ATN(l) = sum(prob_values(Ntest+1:Ntest + Ntest_double + 2*Ntest_attk,2)>steps(l))/(Ntest_double + 2*Ntest_attk);  % fraction of DC + Attacked correctly classified  
    FP(l) = sum(prob_values(1:Ntest,2)>steps(l))/Ntest;  % fraction of SC correctly classified
end

AFN = ones(1,numel(steps)) - ATN;
AUC = abs(trapz(FP,ATN));

% plot ROC curve with AUC value
figure;
plot(FP,ATN,'o-r'); 

hold on
plot(FP,TN,'*-g');

hold on
plot(FP,TN_attack,'*-b');

legend(sprintf('AUC ExtendedNegative: %.2f',abs(trapz(FP,ATN))), sprintf('AUC DoubleComp: %.2f',abs(trapz(FP,TN))), sprintf('AUC Attacked: %.2f',abs(trapz(FP,TN_attack))));

title(['ROC (Aware to ' Proc_Type1 num2str(Proc_Param1) '-' Proc_Type2 num2str(Proc_Param2)  ')']);


%%%%%%%%%%%%%%%%%% save the results in the .mat of the trained SVM %%%%%%%%%%%%%%%%%%%%%%

save(name, 'prob_values', 'Ntest', 'Ntest_double', 'Ntest_attk', 'FP', '-append');


