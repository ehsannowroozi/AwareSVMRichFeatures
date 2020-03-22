
function [CM_img, CM_map] = AutoCopyMove(I, region_width, region_height, source_position, target_position, MARGIN)

% AUTOCOPYMOVE
%
% Input:
%		I               = RGB or grayscale image
%		region_width    = column-size of the region to copy-move
%		region_height   = row-size of the region to copy-move
%		source_position = region of the image where the source patch is copied
%		target_position = region of the image where the source patch is moved 
%		MARGIN			= a value that can be used to avoid copy-move on top of borders.
%						  Larger margins take more central content but may cause overlap
%
% Output:
%		CM_img		    = copy-moved image
%		CM_map			= map of the copy move: pixels=1 for source region, pixels=2 for target, 0 otherwise

if nargin<6
	warning('Usage: [CM_img, CM_map] = AutoCopyMove(I, region_width, region_height, source_position, target_position, MARGIN)')
	return;
end

if MARGIN==0
    MARGIN=1;
end

% Coordinate references
[rows, cols, ~] = size(I);
center = floor([rows/2, cols/2]);

% Map of the copy-move
CM_map = zeros(rows,cols,'uint8');

CM_img = I;

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% COPY SOURCE REGION
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%-----------------------
% Left-side copymoves
%-----------------------
if strcmp(source_position,'left-middle')
	
	src_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	src_coords_c = MARGIN:MARGIN+region_width-1;
	
elseif strcmp(source_position,'left-top')

	src_coords_r = MARGIN:MARGIN+region_height-1;
	src_coords_c = MARGIN:MARGIN+region_width-1;

elseif strcmp(source_position,'left-bottom')	
	
	src_coords_r = rows-MARGIN-region_height+1:rows-MARGIN;
	src_coords_c = MARGIN:MARGIN+region_width-1	;

	
%-----------------------	
% Middle copymoves
%-----------------------
elseif strcmp(source_position,'middle-top')	

	src_coords_r = MARGIN:MARGIN+region_height-1;
	src_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);
	
elseif strcmp(source_position,'middle')	

	src_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	src_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);

elseif strcmp(source_position,'middle-bottom')		
	
	src_coords_r = rows-region_height+1-MARGIN:rows-MARGIN;
	src_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);
	

%-----------------------
% Right-side copymoves
%-----------------------		
elseif strcmp(source_position,'right-middle')	

	src_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	src_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;

elseif strcmp(source_position,'right-bottom')	

	src_coords_r = rows-region_height+1-MARGIN:rows-MARGIN;
	src_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;

elseif strcmp(source_position,'right-top')		
	
	src_coords_r = MARGIN:MARGIN+region_height-1;
	src_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;
	
end
	
% Copy & update map
sourceRegion = CM_img( src_coords_r, src_coords_c,:);	
CM_map( src_coords_r, src_coords_c,:) = 1;
	
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% MOVE TARGET REGION
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%-----------------------	
% Left-side copymoves
%-----------------------
if strcmp(target_position,'left-middle')
	
	tgt_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	tgt_coords_c = MARGIN:MARGIN+region_width-1;
	
elseif strcmp(target_position,'left-top')

	tgt_coords_r = MARGIN:MARGIN+region_height-1;
	tgt_coords_c = MARGIN:MARGIN+region_width-1;

elseif strcmp(target_position,'left-bottom')	
	
	tgt_coords_r = rows-MARGIN-region_height+1:rows-MARGIN;
	tgt_coords_c = MARGIN:MARGIN+region_width-1	;

%-----------------------	
% Middle copymoves
%-----------------------
elseif strcmp(target_position,'middle-top')	

	tgt_coords_r = MARGIN:MARGIN+region_height-1;
	tgt_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);
	
elseif strcmp(target_position,'middle')	

	tgt_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	tgt_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);

elseif strcmp(target_position,'middle-bottom')		
	
	tgt_coords_r = rows-region_height+1-MARGIN:rows-MARGIN;
	tgt_coords_c = center(2)-floor(region_width/2)+1:center(2)+floor(region_width/2);
	

%-----------------------
% Right-side copymoves
%-----------------------		
elseif strcmp(target_position,'right-middle')	

	tgt_coords_r = center(1)-floor(region_height/2)+1:center(1)+floor(region_height/2);
	tgt_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;

elseif strcmp(target_position,'right-bottom')	

	tgt_coords_r = rows-region_height+1-MARGIN:rows-MARGIN;
	tgt_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;

elseif strcmp(target_position,'right-top')		
	
	tgt_coords_r = MARGIN:MARGIN+region_height-1;
	tgt_coords_c = cols-region_width-MARGIN+1:cols-MARGIN;
	
end

% Copy to target region, set target pixels to 2 in the map	
CM_img(tgt_coords_r,tgt_coords_c,:) = sourceRegion;
CM_map(tgt_coords_r,tgt_coords_c,:) = 2;
