function [ Intensity, RedChannel, GreenChannel, BlueChannel, YellowChannel, RG, BY ] = getImageComponents( im )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
RED = im(:,:,1);
GREEN = im(:,:,2);
BLUE = im(:,:,3);
 
%intensity
Intensity = (RED+GREEN+BLUE)/3;
 
%color channels
RedChannel = RED - ((BLUE+GREEN)/2);
GreenChannel = GREEN - ((BLUE+RED)/2);
BlueChannel = BLUE - ((GREEN+RED)/2);
YellowChannel = ((RED+GREEN)/2) - abs((RED-GREEN)/2)-BLUE;
 
%color oponency
RG = RedChannel-GreenChannel;
BY = BlueChannel - YellowChannel; 
 
end