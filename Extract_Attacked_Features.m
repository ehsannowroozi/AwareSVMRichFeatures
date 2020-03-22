
function Extract_Attacked_Features( feature_folder, img_format, ...
    SUBSAMP, QF_1, QF_2, phase, ATTACKS, ATK_PARAMS)

% Each attack must have a parameter set
if numel(ATTACKS) ~= numel(ATK_PARAMS)
    fprintf('Each attack must have a parameter set!')
    return
end

% Images in the folder with given format
image_list = dir([feature_folder '\' phase '\*.' img_format]);

%--------------------------------------------------------------------------
% BASED ON THE SUBSAMPLE FACTOR DETERMINE FOLDER NAME
%--------------------------------------------------------------------------

% Determine image size depending on the specified subsample factor, then
% create a folder with that size. Always use the first image of the
% trainin set, regardless of the phase
tmp_list = dir([feature_folder '\TRAIN\*.' img_format]);
firstImg =  imread([feature_folder '\' phase '\' tmp_list(1).name]);
clear tmp_list
if size(firstImg,1) > size(firstImg,2)
    firstImg = firstImg(:,:,1)';
end

if SUBSAMP == 0
elseif SUBSAMP == 1
    while max(size(firstImg)) > 2200
        firstImg = firstImg(1:2:end,1:2:end,1);
    end
elseif SUBSAMP == 2
    while max(size(firstImg)) > 1600
        firstImg = firstImg(1:2:end,1:2:end,1);
    end
end

% This is the string identifier for the subsampling factor
subsamp = sprintf('sub_%d_%dx%d', SUBSAMP, size(firstImg,1), size(firstImg,2));

% Create folder if it does not exist already
if ~exist([feature_folder 'Features\' subsamp '\' phase], 'dir')
    mkdir([feature_folder 'Features\' subsamp '\' phase])
end


%--------------------------------------------------------------------------
% EXTRACT ATTACKED FEATURES
%--------------------------------------------------------------------------

fprintf('---------------------------------------------------\n')
fprintf(' %s: Attacked features extraction\n', upper(phase))
fprintf('---------------------------------------------------\n')

N = size(image_list,1);

% For all first quality factor ...
for i=1:numel(QF_2)
    
    matfolder = [feature_folder 'Features\' subsamp '\' phase '\' num2str(QF_2(i))];
    
    if ~exist(matfolder, 'dir')
        mkdir(matfolder)
    end
    
    %----------------------------------------------------------------------
    % COMPUTE ATTACKED FEATURES
    %----------------------------------------------------------------------
    
    for s=1:numel(QF_1)
        
        fprintf('  Processing attacked QF_1 = %d, QF_2 = %d ... ', QF_1(s), QF_2(i))
        
        % Initialize feature containers. If we find out later that features
        % of a (Q1,Q2) pair have already been computed, we will delete the
        % useless container while skipping re-computation
        for at=1:numel(ATTACKS)
            
            % This is the file name for attacked features
            feat_variable = sprintf('feat_attacked_%s_%s_%d_%d', ATTACKS{at}, ...
                strrep(num2str(ATK_PARAMS{at}),'.',''), QF_1(s), QF_2(i));
            
            eval( sprintf('%s = zeros(N, 960, ''double'');', feat_variable));
            
        end
        
        % Loop over all the images. For each image, all the attacks are
        % computed. Since there are a lot of images, in fact, reading each
        % time N images for each attack is too expensive
        for n=1:N
            
            % Update progress
            if mod(n,500) == 0
                fprintf([num2str(n) ' '])
            end
            
            % Read image
            I = imread([feature_folder '\' phase '\' image_list(n).name]);
            
            % If color, convert to grayscale
            if size(I,3)>1
                I = rgb2gray(I);
            end
            
            % Depending on the subsample parameter, reduce size
            if SUBSAMP == 0
                % I.E. full size
            elseif SUBSAMP == 1
                while max(size(I)) > 2200
                    I = I(1:2:end,1:2:end);
                end
            elseif SUBSAMP == 2
                while max(size(I)) > 1600
                    I = I(1:2:end,1:2:end);
                end
            else
                fprintf('Wrong subsample parameter! Must be in: [0,1,2]\n')
                return
            end
            
            % Compress once with QF1
            imwrite(I, 'single.jpg', 'jpeg', 'Quality', QF_1(s));
            SQ = imread('single.jpg');
            
            % For each attack ...
            for at=1:numel(ATTACKS)
                
                % This is the file name for attacked features
                feat_file = sprintf('feat_attacked_%s_%s.mat', ATTACKS{at}, ...
                    strrep(num2str(ATK_PARAMS{at}),'.',''));
                
                % Feature container has the same name as file
                feat_container = sprintf('feat_attacked_%s_%s_%d_%d', ATTACKS{at}, ...
                    strrep(num2str(ATK_PARAMS{at}),'.',''), QF_1(s), QF_2(i));
                
                % If files does not exist, create an almost empty one by inserting
                % a timestamp
                if ~exist([matfolder '\' feat_file], 'file')
                    created = datetime;
                    save([matfolder '\' feat_file], 'created')
                end
                
                % Get content of the feat_attacked_XXX_YYY file without loading it
                fileContent = who('-file', [matfolder '\' feat_file]);
                
                % Check whether the current (Q1, Q2) pair is already in the file:
                % if yes, proceed to next QF1
                if ismember(feat_container, fileContent)
                    fprintf('Attack %s (param %s) on pair (%d_%d) already exists, skipping\n', ...
                        ATTACKS{at}, num2str(ATK_PARAMS{at}), QF_1(s), QF_2(i))
                    continue
                end
                
                if strcmp(ATTACKS{at}, 'Desynchronization')
                    params = n;
                else
                    params = ATK_PARAMS{at};
                end
                
                % Attack the single compressed image
                SQ_atk = GenerateAttacked(SQ, ATTACKS{at}, params);
                
                % Compress the attacked image with QF2
                imwrite(SQ_atk, 'attacked.jpg', 'jpeg', 'Quality', QF_2(i))
                
                % Extract features
                x = [spam686('attacked.jpg')', ccpev548_noCal('attacked.jpg')];
                eval(sprintf('%s(n,:) = x;', feat_container))
                
                % Clean
                delete attacked.jpg
                clear SQ_atk x
                
            end
            
            % Clean
            clear I SQ
            delete single.jpg
            
        end
        
        % Save each container into the file which has the same name and
        % then clear the saved container
        for at=1:numel(ATTACKS)
            
            % This is the file name for attacked features
            feat_variable = sprintf('feat_attacked_%s_%s_%d_%d', ATTACKS{at}, ...
                strrep(num2str(ATK_PARAMS{at}),'.',''), QF_1(s), QF_2(i));
            
            feat_file = sprintf('feat_attacked_%s_%s.mat', ATTACKS{at}, ...
                    strrep(num2str(ATK_PARAMS{at}),'.',''));
            
            save([matfolder '\' feat_file], feat_variable, '-append')
            
            eval(sprintf('clear %s', feat_variable))
        end
        
        fprintf(' Done!\n');
        
    end
    
end
