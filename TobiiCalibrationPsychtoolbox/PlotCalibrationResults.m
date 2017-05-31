function myfig = PlotCalibrationResults(calibPlot, Calib)
%PLOTCALIBRATIONPOINTS plots the calibration data for a calibration session
%   Input: 
%         calibPlot: The calibration plot data, specifying the input and output calibration data   
%         Calib: The calib config structure (see SetCalibParams)         
%         mOrder: Vector containing indices indicating the order in which to show the calibration points, [1 2 3 4 5] to show five calibration points in order or [1 3 5 2 4] to show them in different order.
%     
%   Output: 
%         pts: The list of points used for calibration. These could be
%         further used for the analysis such as the variance, mean etc.


    NumCalibPoints = length(calibPlot);
    if (NumCalibPoints == 0 )
        pts = [];
        disp('no calib point found');
        return;
    end
    
    %save('calib_sample.mat', 'calibPlot')
    
    %--- Set up plot preliminaries
    
	myfig = figure('menuBar','none','name','Calibration Result - Press [y]/n to continue','Color', Calib.bkcolor/255,'Renderer', 'Painters','keypressfcn','close;');
	axes('Visible', 'off', 'Units', 'normalize','Position', [0 0 1 1],'NextPlot','replacechildren');
	if (Calib.resize)
		 figloc.x =  Calib.screen.x + Calib.screen.width/4;
		 figloc.y =  Calib.screen.y + Calib.screen.height/4;
		 figloc.width =  Calib.screen.width/2;
		 figloc.height =  Calib.screen.height/2;
	else
		figloc  =  Calib.screen;
	end
	set(myfig,'position',[figloc.x figloc.y figloc.width figloc.height]);
	Calib.mondims = figloc; %(MK doesn't know what this does yet)
	xlim([1,Calib.mondims.width]); 
	ylim([1,Calib.mondims.height]);
    axis ij;
	set(gca,'xtick',[]);set(gca,'ytick',[]);
	hold on
    
    %--- Plot some points!
	for i = 1:NumCalibPoints
		
        %Draw the 'ValidAndUsed' x/y measurements collected for this calib
        %point (red for l eye, green for r eye)
        for j = 1:length(calibPlot(i).LeftEye)
            if strcmp(calibPlot(i).LeftEye(j).Validity,'ValidAndUsed')                
                plot(Calib.mondims.width*calibPlot(i).LeftEye(j).PositionOnDisplayArea(1),...
                    Calib.mondims.height*calibPlot(i).LeftEye(j).PositionOnDisplayArea(2),...
                    'o','MarkerEdgeColor',[1 0 0],...
                    'MarkerFaceColor',[1 0 0],...
                    'MarkerSize',Calib.SmallMark);
            end
            
            if strcmp(calibPlot(i).RightEye(j).Validity,'ValidAndUsed')                
                plot(Calib.mondims.width*calibPlot(i).RightEye(j).PositionOnDisplayArea(1),...
                    Calib.mondims.height*calibPlot(i).RightEye(j).PositionOnDisplayArea(2),...
                    'o','MarkerEdgeColor',[0 1 0],...
                    'MarkerFaceColor',[0 1 0],...
                    'MarkerSize',Calib.SmallMark);
            end
        end
        
        %...and draw the true position on the display on top
		plot(Calib.mondims.width*calibPlot(i).PositionOnDisplayArea(1),...
			Calib.mondims.height*calibPlot(i).PositionOnDisplayArea(2),...
			'o','MarkerEdgeColor',[0 0 1],...
            'MarkerFaceColor',[0 0 1],...
            'MarkerSize',Calib.SmallMark);
        
    end   
    drawnow
end
