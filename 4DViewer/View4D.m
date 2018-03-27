function varargout = View4D(varargin)

% View4D M-file for View4D.fig
%
% View4D is a 3D/4D data viewing application. Three intersecting, orthogonal 
% slices are displayed and the user can click on any pixel to control the
% intersect point. The scrool wheel may be used to increment/decrement the
% respective slice within the volume. 
% The time-activity-curve (TAC) associated with the intersecting pixel is 
% also displayed. Clicking on the TAC controls the time frame (or range of 
% time-frames) displayed on the slices.
% The GUI also lets the user change colormap options, scaling options, time
% frames to display and the operation performed on the time frames.
% Refer to the help option in the View4D menu for additional information.
% 
% Usage:
% ======
% View4D(data) - view the data (a 3D/4D matrix).
% View4D(data, timestr) - sets the 4th dimension frames to display at
%      startup. Refer to filterString2Mask for more details on the
%      string format.
% View4D(data, timestr, property, value, ...) - Pairs of 
%      property and values specific to the volViewer: Properties include:
%  'FigureName' - String of the name of the figure.
%  'FramePanelTitle' - String of title of the frame panel. If not
%      specified, default is 'Time Frames'.
%  'PixelDimensions' - Dimensions of the pixels [dx dy dz] to control the
%      aspect ratio.
%  'Colormap' - sets the colormap to be used. can be either a string to
%      one of the supported colormaps in, or an array definining the
%      colormap. If a string is used, it may be preceded by the letter "i"
%      to indicate inversion on the colormap order.
%  'PointerCallback' - specifies a callback function to execute when
%      user clicks on slices. The function ‘volViewerCoord’ may be used to 
%      determine the coordinates of the point of overlap of the mouse 
%      pointer and the selected object. See DisplayPixelCurve for an
%      example.
%  'Position' - The position on the screen for the window can be specified
%      in two forms:
%      - [x y width height] - in normalized units [0-1].
%      - a string in the format supported by the movegui function.
%  'Time' - The middle frame times
%  'TimeOp' - Operation to carry out on time frames
%            [{'Sum','Average','Weighted Average','Integrate','Max']
%  'TAC' - Additional time activity curves to plot on the time axis.
%  'ExtraSurface' - A surface, whose contours will be superimposed on the
%       slices.
%  'WaitForClose' - Stops execution of calling funcition and waits for the 
%       user to close the View4D figure and then returns the last time 
%       frames used to view.
%
% frames = View4D(...) - Returns the frames selected in the GUI only if
%   'WaitForClose' option was enabled.
%
% See also: filterString2Mask, DisplayPixelCurve

%By Ran Klein, University of Ottawa Heart Institute, 2005
% Modified:
% 2013-12-04  RK  Comments updated before making public.



% Edit the above text to modify the response to help View4D

% Last Modified by GUIDE v2.5 30-May-2013 10:49:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @volViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @volViewer_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if length(varargin)<2
	varargin{2} = '';
end
if nargout
	varargin = [varargin, 'Nargout', nargout];
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before volViewer is made visible.
function volViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for volViewer
handles.output = {nan};
guidata(hObject, handles); % Update handles structure

% get height of panels for future resize
units = get(handles.TimeFramePanel,'units');
set(handles.TimeFramePanel,'units','pixel');
pos = get(handles.TimeFramePanel,'pos');
setappdata(handles.TimeFramePanel,'height',pos(4));
set(handles.TimeFramePanel,'units',units);
% get height of statusbar for future resize
units = get(handles.StatusBar,'units');
set(handles.StatusBar,'units','pixel');
pos = get(handles.StatusBar,'pos');
setappdata(handles.StatusBar,'height',pos(4));
set(handles.StatusBar,'units',units);

if ~isempty(varargin) % Keep the display data
	initializeView4D(handles, varargin);
else
	error('Data not passed to volViewer')
end
set(handles.PlayButton,'BackgroundColor',[0 0.3 0]);
OneWayLoopButton_Callback(handles.OneWayLoopButton,[],handles);
drawnow;
View4DFigure_ResizeFcn(hObject, eventdata, handles);

% Wait until the visibility of the figure is turned off
if getappdata(handles.View4DFigure,'WaitForClose')
	waitfor(handles.View4DFigure,'Visible');
	th = getappdata(handles.View4DFigure,'Timer');
	if ~isempty(th)
		stop(th);
		delete(th);
	end
	try
		delete(getappdata(gcf,'ChildObjects'));
	catch
	end
end


% --- Outputs from this function are returned to the command line.
function varargout = volViewer_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout = handles.output; 
if getappdata(handles.View4DFigure,'WaitForClose')
	
	% Get the selected frames
	if get(handles.SingleFrame,'Value') % Single frame
		frames = num2str(round(get(handles.StartFrameSlider,'Value')));
	elseif get(handles.FrameRange,'Value') % Frame Range
		frames = [num2str(round(get(handles.StartFrameSlider,'Value'))) '-'...
			num2str(round(get(handles.EndFrameSlider,'Value')))];
	elseif get(handles.Other,'Value') % Frame string
		frames = get(handles.FrameString,'String');
	end
	varargout = {frames};
	
	% Close the window once done.
	delete(handles.View4DFigure);
end


% --- Executes on selection change in Colormap.
function Colormap_Callback(hObject, eventdata, handles)
str=get(handles.Colormap,'string');
val=lower(str{get(handles.Colormap,'value')});
if strcmp(val,'custom')
	cmapeditor
else
	cmap=feval(val);
	if get(handles.ColormapInverse,'value')
		cmap = flipud(cmap);
	end
	set(handles.View4DFigure,'colormap',cmap);
end

% --- Executes during object creation, after setting all properties.
function Colormap_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ColormapInverse.
function ColormapInverse_Callback(hObject, eventdata, handles)
Colormap_Callback(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function EndFrameSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function FrameString_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function StartFrame_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function StartFrameSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function MaxIntEdit_Callback(hObject, eventdata, handles)
maxInt = str2num(get(hObject,'string'));
if isempty(maxInt) || maxInt<=0
	set(hObject,'String','');
	GDScale_Callback(hObject, eventdata, handles)
else
	UScale_Callback(hObject, eventdata, handles)
end


% --- Executes during object creation, after setting all properties.
function MaxIntEdit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in UScale.
function UScale_Callback(hObject, eventdata, handles)
set(handles.UScale,'Value',1);
set(handles.GDScale,'Value',0);
set(handles.GSScale,'Value',0);
set(handles.ISScale,'Value',0);
updateView4DSlices(handles);

% --- Executes on button press in GDScale.
function GDScale_Callback(hObject, eventdata, handles)
set(handles.UScale,'Value',0);
set(handles.GDScale,'Value',1);
set(handles.GSScale,'Value',0);
set(handles.ISScale,'Value',0);
updateView4DSlices(handles);

% --- Executes on button press in GSScale.
function GSScale_Callback(hObject, eventdata, handles)
set(handles.UScale,'Value',0);
set(handles.GDScale,'Value',0);
set(handles.GSScale,'Value',1);
set(handles.ISScale,'Value',0);
updateView4DSlices(handles);

% --- Executes on button press in ISScale.
function ISScale_Callback(hObject, eventdata, handles)
set(handles.UScale,'Value',0);
set(handles.GDScale,'Value',0);
set(handles.GSScale,'Value',0);
set(handles.ISScale,'Value',1);
updateView4DSlices(handles);


% --- Executes on mouse press over axes background.
function Axis_ButtonDownFcn(hObject, eventdata, handles)

if ~getappdata(handles.View4DFigure,'ControlLock') % clicking is not diabled?
	if ~strcmpi(get(hObject,'type'),'axes')
		hObject = get(hObject,'parent');
	end
	updateView4DSliceInterstect(hObject, 'Click', handles);
	setappdata(handles.View4DFigure,'CurrentObject',hObject)
end


% --- Executes when View4DFigure is resized.
function View4DFigure_ResizeFcn(hObject, eventdata, handles)
if ~isempty(handles)
	% new figure size in pixels
	if ~isappdata(handles.View4DFigure,'PixelDimensions')
		return
	end
	units = get(handles.View4DFigure,'units');
	set(handles.View4DFigure,'units','pixel');
	FigPos = get(handles.View4DFigure,'position');
	set(handles.View4DFigure,'units',units);
	% fixed height for panels
	panelHeight = getappdata(handles.TimeFramePanel,'height');
	h  = [handles.TimeFramePanel, handles.ColormapPanel, handles.ImageScalingPanel];
	for i = 1:length(h)
		units = get(h(i),'units');
		set(h(i),'units','pixel');
		pos = get(h(i),'pos');
		pos(2) = pos(2) + pos(4)-panelHeight;
		pos(4) = panelHeight;
		set(h(i),'pos',pos);
		set(h(i),'units',units);
	end
	% fixed height for status bar
	statHeight = getappdata(handles.StatusBar,'height');
	units = get(handles.StatusBar,'units');
	set(handles.StatusBar,'units','pixel');
	pos = get(handles.StatusBar,'pos');
	pos(4) = statHeight;
	set(handles.StatusBar,'pos',pos);
	set(handles.StatusBar,'units',units);
	% image and time axes
	vertspace = 20; %pixels
	horzspace = 10; %pixels
	height = ( (FigPos(4) - panelHeight - statHeight) - 2*vertspace) / 2;
	width = (FigPos(3) - horzspace) / 2;
	pix = getappdata(handles.View4DFigure,'PixelDimensions');
	s = size(getappdata(handles.View4DFigure,'RawData'));
	imsize = pix.*s(1:3); %image units
	pix_mm = min([height./imsize([2 3])  width./imsize([1 3])]);
	h = [handles.XAxis, handles.YAxis, handles.ZAxis, handles.TAxis];
	% Account for image sizes to keep axes in same dimensions
	for i = 1:length(h)
		units = get(h(i),'units');
		set(h(i),'units','pixel');
		switch i
			case 3 % top left
 				factor = pix_mm / min([width height]./imsize([1,2]));
				pos = [horzspace+width*(1-factor)/2, statHeight+vertspace+height+height*(1-factor)/2, width*factor, height*factor];
			case 2 % top right
				factor = pix_mm / min([width height]./imsize([3,2]));
				pos = [2*horzspace+width+width*(1-factor)/2, statHeight+vertspace+height+height*(1-factor)/2, width*factor, height*factor];
			case 1 % bottom left
				factor = pix_mm / min([width height]./imsize([1,3]));
				pos = [horzspace+width*(1-factor)/2, statHeight+height*(1-factor)/2, width*factor, height*factor];
			case 4 % bottom right
				pos = [2*horzspace+width, statHeight+40, width-2*horzspace, height-40];
			otherwise
				error('What the f????');
		end
		set(h(i),'Position',pos)
		set(h(i),'units',units);
	end
end


% --- Executes on button press in PlayButton.
function status=PlayButton_Callback(varargin)
hObject = varargin{1};
if nargin>1
	eventdata = varargin{2};
end
if nargin>2
	handles = varargin{3};
end
if ~strcmpi(get(hObject,'type'),'timer')
	th = getappdata(handles.View4DFigure,'Timer');
	if isequal(get(handles.PlayButton,'BackgroundColor'),[0 0.3 0])
		status = 'stop';
	else
		status = 'play';
	end
	if isempty(eventdata) % Start/Stop Play
		startreq = isequal(get(handles.PlayButton,'BackgroundColor'),[0 0.3 0]);
	else
		startreq = strcmpi(eventdata,'start') || strcmpi(eventdata,'play');
	end
	if startreq
		if isempty(th)
			th = timer('ExecutionMode','FixedRate','TimerFcn',@PlayButton_Callback,'UserData',handles.View4DFigure);
% 			th = timer('TimerFcn',View4D('PlayButton_Callback',handles.SingleFrame,[],guidata(handles)));
			setappdata(handles.View4DFigure,'Timer',th);
		end
		set(handles.PlayButton,'String','Stop','BackgroundColor','r');
		set(th,'Period',calcPeriod(get(handles.FrameRateSlider,'Value')));
		start(th);
	else % pause
		if ~isempty(th)
			stop(th);
		end
		set(handles.PlayButton,'String','Play','backgroundColor',[0 0.3 0]);
	end
else % event triggered by the timer
	tic
	status = 'play';
	th = hObject;
	handles = guidata(get(th,'UserData'));
	frame = get(handles.StartFrameSlider,'Value');
	if isequal(get(handles.OneWayLoopButton,'BackgroundColor'),[1 0 0])
		if frame>=get(handles.StartFrameSlider,'Max')
			frame = 1;
		else
			frame = frame + 1;
		end
	elseif getappdata(handles.TwoWayLoopButton,'Forward') % back and forth play
		if frame>=get(handles.StartFrameSlider,'Max') % end of sequence
			frame = frame - 1;
			setappdata(handles.TwoWayLoopButton,'Forward',0)
		else
			frame = frame + 1;
		end
	else
		if frame<=1 % start of sequence
			frame = frame + 1;
			setappdata(handles.TwoWayLoopButton,'Forward',1)
		else
			frame = frame - 1;
		end
	end
	set(handles.StartFrameSlider,'Value',frame);
	View4DFrameSelectionChange(handles.SingleFrame);
end

% --- Executes on slider movement.
function FrameRateSlider_Callback(hObject, eventdata, handles)
th = getappdata(handles.View4DFigure,'Timer');
if ~isempty(th) && strcmpi(get(th,'Running'),'on')
	stop(th);
	set(th,'Period',calcPeriod(get(handles.FrameRateSlider,'Value')));
	start(th);
end

% --- Executes during object creation, after setting all properties.
function FrameRateSlider_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes on button press in OneWayLoopButton.
function OneWayLoopButton_Callback(hObject, eventdata, handles)
set(hObject,'BackgroundColor','r');
set(handles.TwoWayLoopButton,'BackgroundColor',[0.3 0 0]);
drawnow;

% --- Executes on button press in TwoWayLoopButton.
function TwoWayLoopButton_Callback(hObject, eventdata, handles)
set(hObject,'BackgroundColor','r');
set(handles.OneWayLoopButton,'BackgroundColor',[0.3 0 0]);
drawnow;

function val = calcPeriod(val)
val = max(0.01,round(1000*exp(-val))/1000);


% --- Executes on button press in RecordButton.
function RecordButton_Callback(hObject, eventdata, handles)
playing = ~isequal(get(handles.PlayButton,'BackgroundColor'),[0 0.3 0]);
if playing % stop play back
	PlayButton_Callback(hObject, eventdata, handles)
end
[file, path] = uiputfile({'*.gif','Graphics Interchange Format (*.gif)';...
	'*.avi','Audio Video Interleaved file (*.avi)'},'Capture video to...','*.gif');

if ischar(file)
	
	setappdata(handles.View4DFigure,'ControlLock',true)
	h = findobj(handles.View4DFigure,'type','uicontrol');
	set(h,'enable','off')

	if isequal(get(handles.OneWayLoopButton,'BackgroundColor'),[1 0 0]) % one way loop
		frames = 1:get(handles.StartFrameSlider,'Max');
	else % sweep loop
		frames = [1:get(handles.StartFrameSlider,'Max') get(handles.StartFrameSlider,'Max')-1:-1:2];
	end
	
	if strcmpi(file(end-3:end),'.avi')
		aviobj = avifile([path filesep file],'FPS',1/calcPeriod(get(handles.FrameRateSlider,'value')),'Quality',95,'VideoName','Video capture from 4D Viewer.');
	elseif strcmpi(file(end-3:end),'.gif')
		cim = [];
	end
	
	for frame = frames
		set(handles.StartFrameSlider,'Value',frame);
		if ~ishandle(handles.View4DFigure) || strcmpi(get(handles.View4DFigure,'BeingDeleted'),'on')
			break;
		end
		try % might have error if figure is closed
			View4DFrameSelectionChange(handles.SingleFrame);
			drawnow;
			
			if strcmpi(file(end-3:end),'.avi')
				aviobj = addframe(aviobj,getframe(handles.View4DFigure));
			elseif strcmpi(file(end-3:end),'.gif')
				f = getframe(handles.View4DFigure);
				if isempty(cim)
					cim = frame2im(f);
					cim(1,1,1,length(frames))=0;
					fi = 1;
				else
					fi = fi+1;
					cim(:,:,:,fi)=frame2im(f);
				end
			end
		catch
		end
	end
	if strcmpi(file(end-3:end),'.avi')
		aviobj = close(aviobj);
	elseif strcmpi(file(end-3:end),'.gif')
		cim2 = permute(cim,[1 2 4 3]);
		[cim2, cmap] = rgb2ind(reshape(cim2,size(cim,1),[],3),256,'nodither');
		cim2 = reshape(cim2,size(cim,1),size(cim,2),1,size(cim,4));
		imwrite(cim2,cmap,[path filesep file],'gif','DelayTime',calcPeriod(get(handles.FrameRateSlider,'value')),'LoopCount',inf);
	end
	set(h,'enable','on')
	setappdata(handles.View4DFigure,'ControlLock',false);
end

if playing % restart play back
	PlayButton_Callback(hObject, eventdata, handles)
end


function StatusBar_Callback(hObject, eventdata, handles)
% DO NOTHING


function StatusBar_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function WeightedCheckbox_Callback(hObject, eventdata, handles)
% DO NOTHING

function View4DFigure_DeleteFcn(hObject, eventdata, handles)
th = getappdata(handles.View4DFigure,'Timer');
if ~isempty(th) && isvalid(th)
	try
		stop(th);
		delete(th);
	catch
	end
end




% --- Executes on key press with focus on View4DFigure and no controls selected.
function View4DFigure_KeyPressFcn(hObject, eventdata, handles)
key = get(handles.View4DFigure,'CurrentCharacter');
switch key
	case char(28) % left arrow
		set(handles.StartFrameSlider,'value', max(1,get(handles.StartFrameSlider,'value')-1) );
		View4DFrameSelectionChange(handles.StartFrameSlider);
	case char(29) % right arrow
		set(handles.StartFrameSlider,'value', min(get(handles.StartFrameSlider,'Max'), get(handles.StartFrameSlider,'value')+1) );
		View4DFrameSelectionChange(handles.StartFrameSlider);
	case char(31) % down arrow
		if ~get(handles.FrameRange,'value')
			View4DFrameSelectionChange(handles.FrameRange);
		else
			set(handles.EndFrameSlider,'value', max(1,get(handles.EndFrameSlider,'value')-1) );
			View4DFrameSelectionChange(handles.EndFrameSlider);
		end
	case char(30) % up arrow
		if ~get(handles.FrameRange,'value')
			View4DFrameSelectionChange(handles.FrameRange);
		else
			set(handles.EndFrameSlider,'value', min(get(handles.EndFrameSlider,'Max'), get(handles.EndFrameSlider,'value')+1) );
			View4DFrameSelectionChange(handles.EndFrameSlider);
		end
end



% --- Executes on button press in MIPCheckbox.
function MIPCheckbox_Callback(hObject, eventdata, handles)
updateView4DSlices(handles);



% --- Executes on selection change in TimeOperationPopupmenu.
function TimeOperationPopupmenu_Callback(hObject, eventdata, handles)
View4DFrameSelectionChange(handles.TimeOperationPopupmenu)

% --- Executes during object creation, after setting all properties.
function TimeOperationPopupmenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

