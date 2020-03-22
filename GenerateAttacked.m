function[img_proc] = GenerateAttacked(I, proc_type, proc_params)        

% images = dir(DC_dir);
% images = images(3:end);



if strcmp(proc_type,'RotationNN')
            
        img_proc = imRotateCrop(I, proc_params);
        

        
elseif strcmp(proc_type,'Mirroring') 
    
    img_proc = flip(I);
    
 
       
elseif strcmp(proc_type,'Blurring')  % Gaussian smoothing
    
    G = fspecial('gaussian',[3 3], 1);
    img_proc = imfilter(I,G,'same');
    


elseif strcmp(proc_type,'SeamCarving')  
    
   imCol = round((size(I, 2)*9)/10); 
   diffCol = size(I,2) - imCol;
   img_proc = seamcarving(I,diffCol);
    
   
    
        
elseif strcmp(proc_type,'StammDithering')
            
    if proc_params==2
        img_proc = medfilt2(I, [5 5]);
        img_proc = double(img_proc)/255;
        v = var(img_proc(:));
        img_proc = imnoise(img_proc,'gaussian',0, v/1000); 
        
    elseif proc_params==1
        img_proc = medfilt2(I, [3 3]);
        img_proc = double(img_proc)/255;
        v = var(img_proc(:));
        img_proc = imnoise(img_proc,'gaussian',0, v/1000); 
    end

    
    
elseif strcmp(proc_type,'RotationBIC')
            
        img_proc = imRotateCrop(I, proc_params, 'bicubic');
        
        

elseif strcmp(proc_type,'MedianFilter')
            

        img_proc = medfilt2(I, [proc_params,proc_params]);

    
elseif strcmp(proc_type,'HistogramEqualization')
            
   
        
        img_proc = adapthisteq(I); 
        

     
     
  elseif strcmp(proc_type,'HistEq')
                  
        img_proc = histeq(I);
    
     
        
elseif strcmp(proc_type,'Resize')
    
    img_proc = imresize(I, proc_params);
     
    
elseif strcmp(proc_type,'Resize_LinInterp')
    
    img_proc = imresize(I, proc_params, 'bilinear');
  
    
elseif strcmp(proc_type,'Resize_Nearest')
    
    img_proc = imresize(I, proc_params, 'nearest');
    
    
elseif strcmp(proc_type,'WaveletDenoise')
  
  
        noise = NoiseExtract(double(I),MakeONFilter('Daubechies',8),proc_params,4);
        img_proc = uint8(double(I) - noise);
        
        
elseif strcmp(proc_type,'Desyncronization')

    shift= randi([2,7],1,2);
    img_proc = I(shift(1):end, shift(2):end, :);

        
    
elseif strcmp(proc_type,'CopyMove')
    
    MARGIN = 20;
    
    % Possible locations for source and target regions
    SRC_locations = {'left-middle','left-top','left-bottom','middle-top','middle','middle-bottom','right-top','right-middle','right-bottom'};
    TGT_locations = {'left-middle','left-top','left-bottom','middle-top','middle','middle-bottom','right-top','right-middle','right-bottom'};

    % Choose a random location for source among all possible locations
    all_idx = 1:numel(SRC_locations);
    k = randperm(numel(all_idx),1);
    src_loc = SRC_locations{all_idx(k)};

    % Choose a random location for target (except the one used for source)
    all_idx(all_idx==k)=[];
    l = randperm(numel(all_idx),1);
    tgt_loc = SRC_locations{all_idx(l)};
    
    % Copy-move forgery
    [img_proc, M] = AutoCopyMove(I, proc_params,proc_params, src_loc, tgt_loc, MARGIN);
  

    
elseif strcmp(proc_type,'Cropping-Align')
            
    img_proc = I([72:512],[72:512]); 
    

elseif strcmp(proc_type,'Cropping-Not-Align')
            
    img_proc = I([74:514],[74:514]); 
    
     
else
            error('Unknown processing!')
end
        
       
