
function Extract_Single_Double_Features( feature_folder, img_format, ...
    SUBSAMP, QF_1, QF_2, phase) 


% Images in the folder with given format
image_list = dir([feature_folder '\' phase '\*.' img_format]);

%--------------------------------------------------------------------------
% BASED ON THE SUBSAMPLE FACTOR DETERMINE FOLDER NAME
%--------------------------------------------------------------------------
    
% Determine image size depending on the specified subsample factor, then
% create a folder with that size. Always use the first image of the
% trainin set, regardless of the phase
tmp_list = dir([feature_folder '\TRAIN\*.' img_format]);
firstImg =  imread([feature_folder '\TRAIN\' tmp_list(1).name]);
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
% EXTRACT FEATURES
%--------------------------------------------------------------------------
    
fprintf('---------------------------------------------------\n')
fprintf(' %s: Single/Double features extraction\n', upper(phase))
fprintf('---------------------------------------------------\n')

N = size(image_list,1);

% For all first quality factor ...
for i=1:numel(QF_2)
    
    fprintf('Processing single QF_2 = %d ...\n', QF_2(i))
    
    matfolder = [feature_folder 'Features\' subsamp '\' phase '\' num2str(QF_2(i))];
    
    if ~exist(matfolder, 'dir')
        mkdir(matfolder)
    end
    
    %----------------------------------------------------------------------
    % COMPUTE SINGLE COMPRESSED FEATURES IF FILE DOES NOT ALREADY EXIST
    %----------------------------------------------------------------------
    
    % If the file with single compressed features exists already, skip
    if exist([matfolder '\feat_single.mat'], 'file')
        fprintf('  %s already exists, skipping re-computation\n', [matfolder '\feat_single.mat'])
    else
        
        % Create an "almost" empty file with timestamp
        created = datetime;
        save([matfolder '\feat_single.mat'], 'created')
            
        % Start working on features
        feat_single = zeros(N, 960, 'double');
        for n=1:N
            
            % Update progress
            if mod(n,500) == 0
                fprintf([num2str(n) ' '])
            end
            
            % Read image
            I = imread([feature_folder '\' phase '\' image_list(n).name]);
            
            % If color, convert to gray
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
           
            % Compress once with QF2
            imwrite(I, 'single.jpg', 'jpeg', 'Quality', QF_2(i));
            
            % Extract features
            feat_single(n,:) = [spam686('single.jpg')', ccpev548_noCal('single.jpg')];
            
            % Clean
            delete single.jpg      
            clear I
            
        end
        
        var_name = sprintf('feat_single_%d', QF_2(i));
        
        eval(sprintf('%s = feat_single;',var_name))
        
        % Store data
        save([matfolder '\feat_single.mat'], var_name, '-append')
  
        % No need to keep the saved matrix
        clear feat_single
        eval(['clear ' var_name])
    
    end
    fprintf('  Done!\n');
  
    
    %----------------------------------------------------------------------
    % COMPUTE DOUBLE COMPRESSED FEATURES
    %----------------------------------------------------------------------
    
    for s=1:numel(QF_1)
        
        fprintf('  Processing double QF_1 = %d, QF_2 = %d ... ', QF_1(s), QF_2(i))
        
        % If files does not exist, create an almost empty one by inserting
        % a timestamp
        if ~exist([matfolder '\feat_double.mat'], 'file')
            created = datetime;
            save([matfolder '\feat_double.mat'], 'created')
        end
        
        % Get content of the feat_double file without loading it
        fileContent = who('-file', [matfolder '\feat_double.mat']);
        
        % Check whether the current (Q1, Q2) pair is already in the file:
        % if yes, proceed to next QF1
        varname =  sprintf('feat_double_%d_%d', QF_1(s), QF_2(i));       
        if ismember(varname, fileContent)
            fprintf('Pair (%d_%d) already exists, skipping\n', QF_1(s), QF_2(i))
            continue
        end
             
        % If not, compute features of the new pair
        feats = zeros(N, 960, 'double');
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
            
            % Compress a second time with QF2
            imwrite(SQ, 'double.jpg', 'jpeg', 'Quality', QF_2(i))

            % Extract features
            feats(n,:) = [spam686('double.jpg')', ccpev548_noCal('double.jpg')];

            delete single.jpg
            delete double.jpg
            
            clear I SQ

        end
        
        % Rename the variable "feats", containing features of the current
        % pair (Q1, Q2) as "feat_Q1_Q2"
        eval(sprintf('%s = feats;', varname))
     
        % Save features
        save([matfolder '\feat_double.mat'], varname, '-append')
        
        % Clean
        clear feats
        eval(sprintf('clear %s', varname))
        
        fprintf(' Done!\n');

    end
          
end
    