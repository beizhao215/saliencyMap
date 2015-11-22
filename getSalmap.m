function [salmap, saliencyData] = getSalmap(img,params, varargin)

IM = img.data;

%%%%%Read image and get Intensity, R, G, B, Y, RG, BY for original image%%%%%%%%%%%%
%IM = imread('../img/faces.png');
[IMI,IMR,IMG,IMB,IMY,IM_RG,IM_BY]= getImageComponents(IM);
%%%%%Initialize pyramids%%%%%%%%%%%%%%%
Image_pyramid = cell(1,8); %%level 1-8, 1 is 1:2, 8 is 1:256(smallest) 
                            %level 0 should be original image, 
                            %but there's no index 0 in matlab.
IMI_pyramid = cell(1,8);
IMR_pyramid = cell(1,8);
IMG_pyramid = cell(1,8);
IMB_pyramid = cell(1,8);
IMY_pyramid = cell(1,8);
IM_RG_pyramid = cell(1,8);
IM_BY_pyramid = cell(1,8);

%%%%%%Get pyramids for image, intensity, R,G,B,Y,RG,BY%%%%%%%%%%%%%%%%%%
Image_pyramid{1} = impyramid(IM,'reduce'); 
[IMI_pyramid{1},IMR_pyramid{1},IMG_pyramid{1},IMB_pyramid{1},IMY_pyramid{1},IM_RG_pyramid{1},IM_BY_pyramid{1}]= getImageComponents(Image_pyramid{1});

for i = 2:8
    Image_pyramid{i} = impyramid(Image_pyramid{i-1},'reduce');
    [IMI_pyramid{i},IMR_pyramid{i},IMG_pyramid{i},IMB_pyramid{i},IMY_pyramid{i},IM_RG_pyramid{i},IM_BY_pyramid{i}]= getImageComponents(Image_pyramid{i});
end

%%%%Get orientation pyramids%%%%%%%%

Orientation_pyramid = cell(4,8); %first row: 0, second row: 45, third row: 90, fourth row: 135


angles = [0,45,90,135];
for i=1:8
    for j=1:4
        %%%%%%parameters for gabor filter. 
        angle = angles(j);
        %%%IMPORTANT:maybe need to tweak wavelength to get proper filtered orientation
        wavelength = 7; 
        kx = 0.5;
        ky = 0.5;
        showfilter = 1;
        %%%%%% call gabor filter function to get filtered image
        [Eim, Oim, Aim] = spatialgabor(IMI_pyramid{i}, wavelength, angle, kx, ky, showfilter);
 
        Orientation_pyramid{j,i} = Eim;
    end
end

%%%%%%Get feature maps%%%%%%%%%%
c = [2,3,4];
delta = [3,4];
index = 1;
upperLimit = length(c);
lowerLimit = length(delta);
%%%six feature maps for each: 2-5, 2-6, 3-6, 3-7, 4-7, 4-8
RG_feature = cell(1,6);
BY_feature = cell(1,6);
Intensity_feature = cell(1,6);
Orientation_feature = cell(4,6);

for i = 1:upperLimit
    for j=1:lowerLimit
        s = c(i)+delta(j);
        %%%%%%Get RG, BY feature maps%%%%%%%%%
        redgreen_HIGH = IM_RG_pyramid{c(i)};
        blueyellow_HIGH = IM_BY_pyramid{c(i)};
        
        redgreen_LOW = IM_RG_pyramid{s};
        blueyellow_LOW = IM_BY_pyramid{s};
        
        [x_H, y_H] = size(redgreen_HIGH);%%%get size of bigger image
        
        redgreen_LOW = imresize(redgreen_LOW,[x_H,y_H]);%%% interpolation: resize smaller image to bigger image
        RG_feature{index} = abs(redgreen_HIGH - redgreen_LOW);
        
        blueyellow_LOW = imresize(blueyellow_LOW,[x_H,y_H]);
        BY_feature{index} = abs(blueyellow_HIGH - blueyellow_LOW);
        
        %%%%%Get Intensity feature maps%%%%%%%%
        intensity_HIGH = IMI_pyramid{c(i)};
        
        intensity_LOW = IMI_pyramid{s};
                
        intensity_LOW = imresize(intensity_LOW,[x_H,y_H]);
        Intensity_feature{index} = abs(intensity_HIGH - intensity_LOW);
        
        %%%%%%Get Orientation feature maps%%%%%%%%
        for m = 1:4
            orientation_HIGH = Orientation_pyramid{m,c(i)};

            orientation_LOW = Orientation_pyramid{m,s};
        
            orientation_LOW = imresize(orientation_LOW, [x_H, y_H]);
            
            Orientation_feature{m,index} = abs(orientation_HIGH - orientation_LOW);
        end
        
        index = index+1;
    
    end
end


Norm_RG_feature = cell(1,6);
Norm_BY_feature = cell(1,6);
Norm_Intensity_feature = cell(1,6);
Norm_Orientation_feature = cell(4,6);


for i=1:6
    Norm_Intensity_feature{i} = NormalizedImage(Intensity_feature{i});
    Norm_BY_feature{i} = NormalizedImage(BY_feature{i});
    Norm_RG_feature{i} = NormalizedImage(RG_feature{i});
    Norm_Orientation_feature{1,i} = NormalizedImage(Orientation_feature{1,i});
    Norm_Orientation_feature{2,i} = NormalizedImage(Orientation_feature{2,i});
    Norm_Orientation_feature{3,i} = NormalizedImage(Orientation_feature{3,i});
    Norm_Orientation_feature{4,i} = NormalizedImage(Orientation_feature{4,i});
end


[x_4 y_4 z_4] = size(Image_pyramid{4});

Resize_Norm_RG_feature = cell(1,6);
Resize_Norm_BY_feature = cell(1,6);
Resize_Norm_Intensity_feature = cell(1,6);
Resize_Norm_Orientation_feature = cell(4,6);

for i=1:6
    Resize_Norm_Intensity_feature{i} = imresize(Norm_Intensity_feature{i},[x_4,y_4]);
    Resize_Norm_RG_feature{i} = imresize(Norm_RG_feature{i},[x_4,y_4]);
    Resize_Norm_BY_feature{i} = imresize(Norm_BY_feature{i},[x_4,y_4]);
    Resize_Norm_Orientation_feature{1,i} = imresize(Norm_Orientation_feature{1,i},[x_4,y_4]);
    Resize_Norm_Orientation_feature{2,i} = imresize(Norm_Orientation_feature{2,i},[x_4,y_4]);
    Resize_Norm_Orientation_feature{3,i} = imresize(Norm_Orientation_feature{3,i},[x_4,y_4]);
    Resize_Norm_Orientation_feature{4,i} = imresize(Norm_Orientation_feature{4,i},[x_4,y_4]);
end



%summation of maps
ConspicuityMap_Intensity = zeros(x_4,y_4);
ConspicuityMap_Color = zeros(x_4,y_4);
ConspicuityMap_Orientation = zeros(x_4,y_4);
for i=1:6
    ConspicuityMap_Intensity = ConspicuityMap_Intensity+ Resize_Norm_Intensity_feature{i};
    
    ConspicuityMap_Color = ConspicuityMap_Color+ Resize_Norm_RG_feature{i} +Resize_Norm_BY_feature{i};
    
    ConspicuityMap_Orientation = ConspicuityMap_Orientation + Resize_Norm_Orientation_feature{1,i}+Resize_Norm_Orientation_feature{2,i} + Resize_Norm_Orientation_feature{3,i}+ Resize_Norm_Orientation_feature{4,i};
end

finalSaliencyMap = (ConspicuityMap_Intensity+ConspicuityMap_Color+ConspicuityMap_Orientation)/3;





Norm_ConspicuityMap_Intensity = NormalizedImage(ConspicuityMap_Intensity);

Norm_ConspicuityMap_Color = NormalizedImage(ConspicuityMap_Color);

Norm_ConspicuityMap_Orientation = NormalizedImage(ConspicuityMap_Orientation);


finalSaliencyMap = (Norm_ConspicuityMap_Intensity+Norm_ConspicuityMap_Color+Norm_ConspicuityMap_Orientation)/3;

salmap.origImage = img;
salmap.label = 'SaliencyMap';
salmap.data = finalSaliencyMap;
salmap.date = clock;
salmap.parameters = params;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
saliencyData(1,1).origImage = img;
saliencyData(1,1).label = 'Color';
saliencyData(1,1).date = clock;

saliencyData(1,1).pyr(1,1).origImage = img;
saliencyData(1,1).pyr(1,1).label = 'Red/Green';
saliencyData(1,1).pyr(1,1).type = 'dyadic';
saliencyData(1,1).pyr(1,1).date = clock;
saliencyData(1,1).pyr(1,1).levels(1,1).origImage = img;
saliencyData(1,1).pyr(1,1).levels(1,1).label = 'Red/Green-1';
saliencyData(1,1).pyr(1,1).levels(1,1).data = im2double(IM_RG);
saliencyData(1,1).pyr(1,1).levels(1,1).date = clock;
saliencyData(1,1).pyr(1,1).levels(1,1).parameters = params;

for i = 2:9
    saliencyData(1,1).pyr(1,1).levels(1,i).origImage = img;
    saliencyData(1,1).pyr(1,1).levels(1,i).label = 'Red/Green-i';
    saliencyData(1,1).pyr(1,1).levels(1,i).data = im2double(IM_RG_pyramid{1,i-1});
    saliencyData(1,1).pyr(1,1).levels(1,i).date = clock;
    saliencyData(1,1).pyr(1,1).levels(1,i).parameters = params;
end

saliencyData(1,1).pyr(1,2).origImage = img;
saliencyData(1,1).pyr(1,2).label = 'Blue/Yellow';
saliencyData(1,1).pyr(1,2).type = 'dyadic';
saliencyData(1,1).pyr(1,2).levels(1,1).origImage = img;
saliencyData(1,1).pyr(1,2).levels(1,1).label = 'Blue/Yellow-1';
saliencyData(1,1).pyr(1,2).levels(1,1).data = im2double(IM_BY);% pyramid
saliencyData(1,1).pyr(1,2).levels(1,1).date = clock;
saliencyData(1,1).pyr(1,2).levels(1,1).parameters = params;
for i = 2:9
    saliencyData(1,1).pyr(1,2).levels(1,i).origImage = img;
    saliencyData(1,1).pyr(1,2).levels(1,i).label = 'Blue/Yellow-i';
    saliencyData(1,1).pyr(1,2).levels(1,i).data = im2double(IM_BY_pyramid{1,i-1});
    saliencyData(1,1).pyr(1,2).levels(1,i).date = clock;
    saliencyData(1,1).pyr(1,2).levels(1,i).parameters = params;
end

for i=1:6
    saliencyData(1,1).FM(1,i).origImage = img;
    saliencyData(1,1).FM(1,i).label = 'Red/Green';
    saliencyData(1,1).FM(1,i).data = im2double(Resize_Norm_RG_feature{1,i});
    saliencyData(1,1).FM(1,i).date = clock;
    saliencyData(1,1).FM(1,i).parameters = params;

    saliencyData(1,1).FM(2,i).origImage = img;
    saliencyData(1,1).FM(2,i).label = 'Blue/Yellow';
    saliencyData(1,1).FM(2,i).data = im2double(Resize_Norm_BY_feature{1,i});
    saliencyData(1,1).FM(2,i).date = clock;
    saliencyData(1,1).FM(2,i).parameters = params;
end

for i=1:2 
    saliencyData(1,1).csLevels(i,1).centerLevel = 3;
    saliencyData(1,1).csLevels(i,1).surrondLevel = 6;
    saliencyData(1,1).csLevels(i,2).centerLevel = 3;
    saliencyData(1,1).csLevels(i,2).surrondLevel = 7;
    saliencyData(1,1).csLevels(i,3).centerLevel = 4;
    saliencyData(1,1).csLevels(i,3).surrondLevel = 7;
    saliencyData(1,1).csLevels(i,4).centerLevel = 4;
    saliencyData(1,1).csLevels(i,4).surrondLevel = 8;
    saliencyData(1,1).csLevels(i,5).centerLevel = 5;
    saliencyData(1,1).csLevels(i,5).surrondLevel = 8;
    saliencyData(1,1).csLevels(i,6).centerLevel = 5;
    saliencyData(1,1).csLevels(i,6).surrondLevel = 9;
end

saliencyData(1,1).CM.origImage = img;
saliencyData(1,1).CM.label = 'ColorCM';
saliencyData(1,1).CM.data = Norm_ConspicuityMap_Color;
saliencyData(1,1).CM.date = clock;
saliencyData(1,1).CM.parameters = params;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
saliencyData(1,2).origImage = img;
saliencyData(1,2).label = 'Intensities';
saliencyData(1,2).pyr.origImage = img;
saliencyData(1,2).date = clock;

saliencyData(1,2).pyr.origImage = img;
saliencyData(1,2).pyr.label = 'Intensity';
saliencyData(1,2).pyr.type = 'dyadic';
saliencyData(1,2).pyr.date = clock;
saliencyData(1,2).pyr.levels(1,1).origImage = img;
saliencyData(1,2).pyr.levels(1,1).label = 'Intensity-1';
saliencyData(1,2).pyr.levels(1,1).data = im2double(IMI);
saliencyData(1,2).pyr.levels(1,1).date = clock;
saliencyData(1,2).pyr.levels(1,1).parameters = params;
for i = 2:9
    saliencyData(1,2).pyr.levels(1,i).origImage = img;
    saliencyData(1,2).pyr.levels(1,i).label = 'Intensity-i';
    saliencyData(1,2).pyr.levels(1,i).data = im2double(IMI_pyramid{1,i-1});
    saliencyData(1,2).pyr.levels(1,i).date = clock;
    saliencyData(1,2).pyr.levels(1,i).parameters = params;
end

for i=1:6
    saliencyData(1,2).FM(1,i).origImage = img;
    saliencyData(1,2).FM(1,i).label = 'Intensity';
    saliencyData(1,2).FM(1,i).data = im2double(Resize_Norm_Intensity_feature{1,i});
    saliencyData(1,2).FM(1,i).date = clock;
    saliencyData(1,2).FM(1,i).parameters = params;
end

for i=1:1
    saliencyData(1,2).csLevels(i,1).centerLevel = 3;
    saliencyData(1,2).csLevels(i,1).surrondLevel = 6;
    saliencyData(1,2).csLevels(i,2).centerLevel = 3;
    saliencyData(1,2).csLevels(i,2).surrondLevel = 7;
    saliencyData(1,2).csLevels(i,3).centerLevel = 4;
    saliencyData(1,2).csLevels(i,3).surrondLevel = 7;
    saliencyData(1,2).csLevels(i,4).centerLevel = 4;
    saliencyData(1,2).csLevels(i,4).surrondLevel = 8;
    saliencyData(1,2).csLevels(i,5).centerLevel = 5;
    saliencyData(1,2).csLevels(i,5).surrondLevel = 8;
    saliencyData(1,2).csLevels(i,6).centerLevel = 5;
    saliencyData(1,2).csLevels(i,6).surrondLevel = 9;
end

saliencyData(1,2).CM.origImage = img;
saliencyData(1,2).CM.label = 'IntensitiesCM';
saliencyData(1,2).CM.data = Norm_ConspicuityMap_Intensity;
saliencyData(1,2).CM.date = clock;
saliencyData(1,2).CM.parameters = params;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
saliencyData(1,3).origImage = img;
saliencyData(1,3).label = 'Orientations';
saliencyData(1,3).date = clock;

saliencyData(1,3).pyr(1,1).origImage = img;
saliencyData(1,3).pyr(1,1).label = 'Gabor0.0';
saliencyData(1,3).pyr(1,1).type = 'dyadic';
saliencyData(1,3).pyr(1,1).date = clock;

for i = 2:9
    saliencyData(1,3).pyr(1,1).levels(1,i).origImage = img;
    saliencyData(1,3).pyr(1,1).levels(1,i).label = 'Gabor0.0';
    saliencyData(1,3).pyr(1,1).levels(1,i).data = im2double(Orientation_pyramid{1,i-1});
    saliencyData(1,3).pyr(1,1).levels(1,i).date = clock;
    saliencyData(1,3).pyr(1,1).levels(1,i).parameters = params;
end

saliencyData(1,3).pyr(1,2).origImage = img;
saliencyData(1,3).pyr(1,2).label = 'Gabor45.0';
saliencyData(1,3).pyr(1,2).type = 'dyadic';
saliencyData(1,3).pyr(1,2).date = clock;

for i = 2:9
    saliencyData(1,3).pyr(1,2).levels(1,i).origImage = img;
    saliencyData(1,3).pyr(1,2).levels(1,i).label = 'Gabor45.0';
    saliencyData(1,3).pyr(1,2).levels(1,i).data = im2double(Orientation_pyramid{2,i-1});
    saliencyData(1,3).pyr(1,2).levels(1,i).date = clock;
    saliencyData(1,3).pyr(1,2).levels(1,i).parameters = params;
end

saliencyData(1,3).pyr(1,3).origImage = img;
saliencyData(1,3).pyr(1,3).label = 'Gabor90.0';
saliencyData(1,3).pyr(1,3).type = 'dyadic';
saliencyData(1,3).pyr(1,3).date = clock;

for i = 2:9
    saliencyData(1,3).pyr(1,3).levels(1,i).origImage = img;
    saliencyData(1,3).pyr(1,3).levels(1,i).label = 'Gabor90.0';
    saliencyData(1,3).pyr(1,3).levels(1,i).data = im2double(Orientation_pyramid{3,i-1});
    saliencyData(1,3).pyr(1,3).levels(1,i).date = clock;
    saliencyData(1,3).pyr(1,3).levels(1,i).parameters = params;
end

saliencyData(1,3).pyr(1,4).origImage = img;
saliencyData(1,3).pyr(1,4).label = 'Gabor135.0';
saliencyData(1,3).pyr(1,4).type = 'dyadic';
saliencyData(1,3).pyr(1,4).date = clock;

for i = 2:9
    saliencyData(1,3).pyr(1,4).levels(1,i).origImage = img;
    saliencyData(1,3).pyr(1,4).levels(1,i).label = 'Gabor135.0';
    saliencyData(1,3).pyr(1,4).levels(1,i).data = im2double(Orientation_pyramid{4,i-1});
    saliencyData(1,3).pyr(1,4).levels(1,i).date = clock;
    saliencyData(1,3).pyr(1,4).levels(1,i).parameters = params;
end


for i=1:6
    saliencyData(1,3).FM(1,i).origImage = img;
    saliencyData(1,3).FM(1,i).label = 'Gabor0.0';
    saliencyData(1,3).FM(1,i).data = im2double(Resize_Norm_Orientation_feature{1,i});    
    saliencyData(1,3).FM(1,i).date = clock;
    saliencyData(1,3).FM(1,i).parameters = params;
    
    saliencyData(1,3).FM(2,i).origImage = img;
    saliencyData(1,3).FM(2,i).label = 'Gabor45.0';
    saliencyData(1,3).FM(2,i).data = im2double(Resize_Norm_Orientation_feature{2,i});    
    saliencyData(1,3).FM(2,i).date = clock;
    saliencyData(1,3).FM(2,i).parameters = params;
    
    saliencyData(1,3).FM(3,i).origImage = img;
    saliencyData(1,3).FM(3,i).label = 'Gabor90.0';
    saliencyData(1,3).FM(3,i).data = im2double(Resize_Norm_Orientation_feature{3,i});
    saliencyData(1,3).FM(3,i).date = clock;
    saliencyData(1,3).FM(3,i).parameters = params;
    
    saliencyData(1,3).FM(4,i).origImage = img;
    saliencyData(1,3).FM(4,i).label = 'Gabor135.0';
    saliencyData(1,3).FM(4,i).data = im2double(Resize_Norm_Orientation_feature{4,i});
    saliencyData(1,3).FM(4,i).date = clock;
    saliencyData(1,3).FM(4,i).parameters = params;
end

for i=1:4
    saliencyData(1,3).csLevels(i,1).centerLevel = 3;
    saliencyData(1,3).csLevels(i,1).surroundLevel = 6;
    saliencyData(1,3).csLevels(i,2).centerLevel = 3;
    saliencyData(1,3).csLevels(i,2).surroundLevel = 7;
    saliencyData(1,3).csLevels(i,3).centerLevel = 4;
    saliencyData(1,3).csLevels(i,3).surroundLevel = 7;
    saliencyData(1,3).csLevels(i,4).centerLevel = 4;
    saliencyData(1,3).csLevels(i,4).surroundLevel = 8;
    saliencyData(1,3).csLevels(i,5).centerLevel = 5;
    saliencyData(1,3).csLevels(i,5).surroundLevel = 8;
    saliencyData(1,3).csLevels(i,6).centerLevel = 5;
    saliencyData(1,3).csLevels(i,6).surroundLevel = 9;
end

saliencyData(1,3).CM.origImage = img;
saliencyData(1,3).CM.label = 'OrientationsCM';
saliencyData(1,3).CM.data = Norm_ConspicuityMap_Orientation;
saliencyData(1,3).CM.date = clock;
saliencyData(1,3).CM.parameters = params;

%imshow(finalSaliencyMap);







