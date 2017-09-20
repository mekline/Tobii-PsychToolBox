function StimulusOnsetTime=twirl(win,totTime,ifi,when0,position)
% StimulusOnsetTime=swirl(win,totTime,ifi,when0,position)
% This function draws a swirly pattern
% win is the window handle returned from psyhctoolbox when it iniatialises
% the screen context that it draws in
% totTime is the time in seconds that the swirling pattern lasts
% ifi is the time returned by the Screen('GetFlipInterval') command
% when0 is the time to start displaying the swirly pattern
% position is the x, y screen coordinates of where to centre the swirly
% pattern

rand('state',sum(100*clock));
pos = position; %Remember these are always specified in the [0,1] range

rect=Screen('Rect',win);
cx = pos(1)*rect(3); %...so convert'em to this screen size
cy = pos(2)*rect(4);

global BACKCOLOR;
BACKCOLOR = [0 0 0];

%What poly & color?
sides=floor(rand*3)+3; %How many sided poly?
color = SetColor(BACKCOLOR); %Choose a random pretty color

%How will it move?
numSteps = 120; %This controls how fast the spin goes...
dt = totTime/numSteps;
size=75; 
decr = 3;
dir=floor(rand*2)*2-1;
ainc=dir*2*pi*0.01; %0.016
angle=2*pi*rand;

time01 = 0;
time02 = 0;

when = when0;
for i=1:numSteps
    RegPoly(win,sides,size,angle,color,cx,cy); %Get current poly
    Screen('DrawingFinished',win);
    %Prep next rotation
    if(abs(size) > 75)
    	decr = -decr;
    	color = SetColor(color);
    end
    if (size == 0)
    	color = SetColor(color);
    end
    size=round(size-decr); 
    angle=angle+ainc;
    
    [now StimulusOnsetTime FlipTimestamp Missed Beampos]= Screen('Flip',win, when);
    when = StimulusOnsetTime+dt-ifi;    
end

return


%%
function RegPoly(win,sides,size,angle,color,cx,cy)
%Draws a polygon at the specified position and tilt

%cx=rect(3)/2;
%cy=rect(4)/2;
for i=1:sides
    vert(i,1)=cx+size*cos(angle+2*pi*(i-1)/sides);
    vert(i,2)=cy+size*sin(angle+2*pi*(i-1)/sides);
end
Screen('FillPoly', win, color, vert);
return

%%
function color=SetColor(oldcolor)
%Sets a nice bright polygon color (for a white background)

color=round(rand(3,1)*150); %Darker colors

%Make sure it's not too muddy, AND different from the last color
lastwhite = find(oldcolor == 255);
if lastwhite
	switch lastwhite
		case 1
			color(floor(rand*2)+2) = 255; %set 2 or 3;
		case 2
		    color(floor(rand*2)*2+1) = 255; %set 1 or 3, etc.
		case 3
			color(floor(rand*2)+1) = 255;	
	end
else
	color(floor(rand*3)+1)=255;
end


return
