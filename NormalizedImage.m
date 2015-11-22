function [NormalizedMap] = NormalizedImage(OriginalMap1)

OriginalMap = mat2gray(OriginalMap1);
       

globalMaxVec = max(OriginalMap);
globalMaxVal = max(globalMaxVec);

[x y]=size(OriginalMap);
pks=zeros(x,y);
count =0;
for i=2:x-1
    for j=2:y-1
        
        tempVal = OriginalMap(i,j);
        if(tempVal > OriginalMap(i-1,j) && OriginalMap(i+1,j) && OriginalMap(i,j-1) && OriginalMap(i, j+1))
            pks(i,j)= tempVal;
            
            count = count+1;
        else
            pks(i,j) = 0;
        end
  
    end
end

if(count==0)
    AverageMaxima=0;
else
    AverageMaxima = (sum(pks(:)))/count;
end

mult = (globalMaxVal - AverageMaxima)^2;


NormalizedMap = mult.*OriginalMap;