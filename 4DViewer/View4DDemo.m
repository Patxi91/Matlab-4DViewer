% View4DDemo - load demo data and call View4D.
%
% See comments below about modes of operation in the demo.
% Type 'help View4D' to get help on the View4D function usage.
%
% See also: View4D, DisplayPixelCurve

% By Ran Klein, University of Ottawa Heart Institute, 2013-12-04


%% Change mode of operation:
% false - Do not stop and wait. Just generate display and finish execution.
% true -  Stop and wait for user to close View4D. Returns the time frames
%         selected to generate the last display.
waitForClose = false;

%% Load demo data
load('View4DDemoData.mat')

%% Call 4DViewer with all options
frames = View4D(vol,... % 4D volume data
	'13-15',... % time frames to display at startup
	'PixelDimensions',[xdim, ydim, zdim],... % pixel spacial dimension sizes
	'Time',time,'TimeUnits',timeUnits,... frame times and units
	'TimeOp','Sum',...
	'Units',uptakeUnits,... image units name
	'TAC',TAC,... % Time-activity-curves to add to the time axis
	'ExtraSurface',ROIdata,... % contours/surface data to add to the slices
	'Position','north',... figure position
	'FigureName','View4D Demo',... % Name of the figure
	'AxisNames',{'Coronal','Sagittal','Transaxial'},... axis labels   
	'Colormap','HotMetal',... The image colormap
	'WaitForClose',waitForClose,...
	'PointerCallback','DisplayPixelCurve'); % The callback function used to generate a live display when a new intersection pixel is selected

disp('Done View4D call');

%% Display results
if waitForClose
	disp(['Frames ' frames ' were last used in View4D']);
end