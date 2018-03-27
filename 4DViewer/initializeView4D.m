function initializeView4D(handles, p)
% Initialize the View4D display at the creation of the GUI.
%
% Usage:
% ------
% initializeView4D(handles, p)
% where inputs are:
%   handles - the handle strucutre to the GUI components.
%   p - the parameters passed by the user, as follows:
%   p{1} - The data to display - as a 3D/4D matrix.
%   p{2} - Time frames mask string to be summed for the display by default.
%          If not specified, last frame is default.
%   p{3...} - Pairs of property and value are documented in View4D.
%
% See also: View4D

%By Ran Klein, University of Ottawa Heart Institute, 2005

error(nargchk(2, 3, nargin)); % narginchk(2,2);   Changed 2014-01-08 to be backwards compatible with Matlab 2010a and earlier

%% Set the progressbar
wbh = waitbar(0,'Creating 4D Viewer window. Please wait','WindowStyle','Modal');

%% Configure the View4D Figure Renderer
% Set the renderer to OpenGL if possible.
try
	set(handles.View4DFigure,'Renderer','OpenGL')
catch
	warning('Failed to find OpenGL renderer.');
end
if ~strcmp(get(handles.View4DFigure,'renderer'),'OpenGL')
	warning('Renderer is not OpenGL. Some graphic features, such as transperacy, may not be displayed properly.');
end

%% Configure the View4D Figure Toolbars
delete(findobj(get(handles.View4DFigure,'Children'),'type','uitoolbar'));

%% Store data and set up Display Axes
% Check and condition volume data
if islogical(p{1})
	p{1} = double(p{1});
end

% Update gui variables
setappdata(handles.View4DFigure,'RawData',p{1});
setappdata(handles.View4DFigure,'SummedData',p{1}(:,:,:,end));
setappdata(handles.GDScale,'Scale',[0 max(p{1}(:))]);
setappdata(handles.View4DFigure,'PixelDimensions',[1 1 1]);
s = size(p{1});
if length(s)>3
	setappdata(handles.View4DFigure,'TimePoints',1:s(4))
else
	setappdata(handles.View4DFigure,'TimePoints',[])
end
slice = max(1,round(s/2));
ah = [handles.XAxis, handles.YAxis, handles.ZAxis];
for i=1:3
	setappdata(ah(i),'Slice',slice(i));
end
% Unlock the controls by default
setappdata(handles.View4DFigure,'ControlLock',false) 
	
% Reset the axes
delete(get(handles.XAxis,'children'))
delete(get(handles.YAxis,'children'))
delete(get(handles.ZAxis,'children'))
cla(handles.TAxis);

%% Time Frames
waitbar(0.2,wbh,'Applying frame settings. Please wait');
if length(s)==4 % Is this a time sequence of volumes
	step = 1/(s(4)-1);
	set(handles.StartFrameSlider,'Min',1,'Max',s(4),'Value',1,'SliderStep',[step max(0.1, step)]);
	set(handles.EndFrameSlider,'Min',1,'Max',s(4),'Value',1,'SliderStep',[step max(0.1, step)]);
	if length(p)>2 && ~isempty(p{2}) % Time frames to display have been passed as a parameter
		if ischar(p{2}) % If a string was passed
			timeFrames = filterString2Mask(p{2},s(4)); % convert to mask
		else
			timeFrames = p{2};
		end
		if ischar(timeFrames) % Still a string??? 
			timeFrames = s(4); % Bad string was passed - use last frame
			warning('%s is not a valid filter string. Last frame used in place.' ,p{2});
		elseif length(timeFrames)>1 %Otherwis if an array
			if ~all(timeFrames(2:end)-timeFrames(1:end-1) == 1) % if not a continous range
				timeFrames = p{2}; % then use the string
			end
		elseif isempty(timeFrames)
			timeFrames = s(4);
		end
	else
		timeFrames = s(4); % Default is the last time frames
	end
	
	if ischar(timeFrames) % Other string
		set(handles.SingleFrame,'Value',0);
		set(handles.FrameRange,'Value',0);
		set(handles.Other,'Value',1);
		set(handles.StartFrameSlider,'Value',1,'Enable','Off');
		set(handles.StartFrame,'String',1);
		set(handles.EndFrameSlider,'Value',1,'Enable','Off');
		set(handles.EndFrame,'String',1);
		set(handles.FrameString,'String',timeFrames);
	elseif length(timeFrames)==1 % Single Frame
		set(handles.SingleFrame,'Value',1);
		set(handles.FrameRange,'Value',0);
		set(handles.Other,'Value',0);
		set(handles.StartFrameSlider,'Value',timeFrames,'Enable','On');
		set(handles.StartFrame,'String',timeFrames);
		set(handles.EndFrameSlider,'Value',timeFrames,'Enable','Off');
		set(handles.EndFrame,'String',timeFrames,'Enable','Off');
		set(handles.FrameString,'String','','Enable','Off');
	else  % Range
		set(handles.SingleFrame,'Value',0);
		set(handles.FrameRange,'Value',1);
		set(handles.Other,'Value',0);
		set(handles.StartFrameSlider,'Value',timeFrames(1),'Enable','On');
		set(handles.StartFrame,'String',timeFrames(1));
		set(handles.EndFrameSlider,'Value',timeFrames(end),'Enable','On');
		set(handles.EndFrame,'String',timeFrames(end));
		set(handles.FrameString,'String','','Enable','Off');
	end

	% Callbacks
	set([handles.SingleFrame, handles.FrameRange, handles.Other,...
		handles.StartFrameSlider, handles.EndFrameSlider,...
		handles.FrameString, handles.TimeOperationPopupmenu],...
		'Callback','View4DFrameSelectionChange(gcbo)');
else % Not a time sequence - just a volume image -  no frame selection controls
	set(handles.SingleFrame,'Value',1);
	set(handles.FrameRange,'Value',0);
	set(handles.Other,'Value',0);
	set([handles.StartFrameSlider handles.EndFrame],'Value',0);
	set([handles.StartFrame handles.EndFrame],'String','');
	
	set([handles.SingleFrame, handles.FrameRange, handles.Other,...
		handles.StartFrameSlider, handles.EndFrameSlider,...
		handles.FrameString],...
		'Enable','off');
end

%% Default parameter values
setappdata(handles.View4DFigure,'axisTitles',{'Coronal','Sagittal','Transverse'});

%% Property and value pairs specified in function call
i=3;
pos = [];
while i<length(p)
	switch lower(p{i})
		case 'figurename'
			set(handles.View4DFigure,'Name',p{i+1});
		case 'framepaneltitle'
			if ischar(p{i+1})
				set(handles.TimeFramePanel,'Title',p{i+1});
			else
				msgID = sprintf('FADSTool:%s:wrongDataType',mfilename);
				error(msgID, 'FramePanelTitle property must be of type character.');
			end
		case 'axisnames'
			setappdata(handles.View4DFigure,'axisTitles',p{i+1});
		case 'colormap'
			if ischar(p{i+1})
				if lower(p{i+1}(1))=='i'
					colormapInv = true;
					colormapName = p{i+1}(2:end);
				else
					colormapInv = false;
					colormapName = p{i+1};
				end
				set(handles.ColormapInverse,'value',colormapInv);
				cmap=feval(lower(colormapName),128);
				if get(handles.ColormapInverse,'value')
					cmap = flipud(cmap);
				end
				set(handles.View4DFigure,'colormap',cmap);
			else
				set(handles.View4DFigure,'colormap',p{i+1});
				colormapName = 'Custom';
			end
			colorMaps = get(handles.Colormap,'string');
			vi = find(strcmpi(colorMaps,colormapName),1);
			if isempty(vi)
				vi=1;
			end
			set(handles.Colormap,'Value',vi);
		case 'time'
			if length(p{i+1}) > 1 && length(s)==4 && length(p{i+1})== s(4)
				setappdata(handles.View4DFigure,'TimePoints',p{i+1})
			end
			set(handles.TimeOperationPopupmenu,'string',...
				{'Sum';'Average';'Weighted Average';'Integrate';'Max'});
		case 'timeop'
			setPullDownValue(handles.TimeOperationPopupmenu,p{i+1});
		case 'timeunits'
			setappdata(handles.View4DFigure,'TimeUnits',p{i+1})
		case 'units'
			setappdata(handles.View4DFigure,'Units',p{i+1})
		case 'pointercallback'
			setappdata(handles.View4DFigure,'PointerCallback',p{i+1});
		case 'position'
			pos = p{i+1};
		case 'pixeldimensions'
			setappdata(handles.View4DFigure,'PixelDimensions',p{i+1});
		case 'tac'
			setappdata(handles.TAxis,'TAC',p{i+1});
		case 'extrasurface'
			setappdata(handles.View4DFigure,'Contour',p{i+1});
		case 'waitforclose'
			setappdata(handles.View4DFigure,'WaitForClose',p{i+1})
		case 'nargout'
			% Do nothing
		otherwise
			msgID = sprintf('FADSTool:%s:unknownProperty',mfilename);
			error(msgID, 'There is no ''%s'' property in 4D Viewer', p{i});
	end
	i=i+2;
end
if i==length(p) && i>3
	msgID = sprintf('FADSTool:%s:noPropertyValue',mfilename);
	error(msgID, 'No value passed to property ''%s''.', p{i})
end

%% Position the figure
% if ~isempty(pos)
% 	if ischar(pos)
% 		movegui(handles.View4DFigure ,pos);
% 		drawnow;
% 	else
% 		set(handles.View4DFigure,'units','normalized','position',pos);
% 	end
% end
setappdata(handles.View4DFigure,'DefPos',pos);


%% Update the display
waitbar(0.5,wbh,'Computing data display. Please wait.');
View4DFrameSelectionChange(handles.View4DFigure);
waitbar(0.9,wbh,'Applying settings. Please wait.');

%% Close Request Function Callback depends of WaitForClose functionality
if getappdata(handles.View4DFigure,'WaitForClose')
	set(handles.View4DFigure,'CloseRequestFcn','set(gcf,''Visible'',''off'');');
else
	set(handles.View4DFigure,'CloseRequestFcn','th = getappdata(gcf,''Timer''); if ~isempty(th), stop(th); delete(th); end, try, delete(getappdata(gcf,''ChildObjects'')); catch, end, delete(gcf)');
end

%% Adjust the TAC axes time lmits
% use the middle sample time to estimate the frame start times and frame lengths.
[frame_len, frame_start] = mst2frameTimes(getappdata(handles.View4DFigure,'TimePoints'));
if isempty(frame_len)
	frame_len = 1;
	frame_start = 0;
end
set(handles.TAxis,'xlim',[0 frame_len(end)+frame_start(end)]);

%% Set the callback functions
set(handles.View4DFigure,'Pointer','arrow','Visible','On','WindowButtonUpFcn',@ReleaseOBJ,'WindowButtonMotionFcn',@MoveOBJ,'WindowScrollWheelFcn',@ScrollWheel);
% This section has to be after figure visibliity is turned on otherwise
% positioning may not catch
if ~isempty(pos)
	if ischar(pos)
		movegui(handles.View4DFigure ,pos);
	else
		set(handles.View4DFigure,'units','normalized','position',pos);
	end
end

%% Close the waitbar
close(wbh); 




%  =============================================================
%% Additional Callback Functions


% --- Callback function when the mouse button is released on the View4D figure
function ReleaseOBJ(hObject, event, handles)
hObject = getappdata(gcf,'CurrentObject');
if ~isempty(hObject)
	handles = guidata(hObject);
	ah = get(hObject,'parent');
	if ah == handles.TAxis
		pos = get(ah,'CurrentPoint'); pos = pos(1, 1:2);
		time = getappdata(handles.View4DFigure,'TimePoints');
		times = time;
		if pos(1)>time(end)
			time = time(end);
		elseif pos(1)<time(1)
			time = time(1);
		else
			time = interp1(time, time, pos(1),'nearest');
		end
		time = [get(hObject,'UserData'), time];
		if time(1)>time(2)
			time = [time(2) time(1)];
		end
		set(handles.StartFrameSlider,'Value',find(times==time(1)));
		set(handles.StartFrame,'String',num2str(get(handles.StartFrameSlider,'Value')));
		if time(1)==time(2)
			View4DFrameSelectionChange(handles.SingleFrame);
		else
			set(handles.EndFrameSlider,'Value',find(times==time(2)));
			set(handles.EndFrame,'String',num2str(get(handles.EndFrameSlider,'Value')));
			View4DFrameSelectionChange(handles.FrameRange);
		end
	elseif any(hObject == [handles.XAxis, handles.YAxis, handles.ZAxis])
		% Additional callback after pointer move
		if ~isempty(getappdata(handles.View4DFigure,'PointerCallback'))
			feval(getappdata(handles.View4DFigure,'PointerCallback'), hObject, '', handles)
		end
	end
end
setappdata(gcf,'CurrentObject',[]);


% --- Callback function when the mouse pointer is moved on the View4D figure
function MoveOBJ(hObject, eventdata, handles)
hObject = getappdata(gcf,'CurrentObject');
if ~isempty(hObject)
	handles = guidata(hObject);
	ah = get(hObject,'parent');
	if ah == handles.TAxis
		pos = get(ah,'CurrentPoint'); pos = pos(1, 1:2);
		time = getappdata(handles.View4DFigure,'TimePoints');
		if pos(1)>time(end)
			time = time(end);
		elseif pos(1)<time(1)
			time = time(1);
		else
			time = interp1(time, time, pos(1),'nearest');
		end
		time = sort([get(hObject,'UserData') time]);
		if 1
			times = getappdata(handles.View4DFigure,'TimePoints');
			istart = find(time(1)==times);
			iend = find(time(2)==times);
			[frame_len, frame_start] = mst2frameTimes(times,1);
			time(1) = frame_start(istart);
			time(2) = frame_start(iend)+frame_len(iend);
		end
		a = axis(ah);
		set(hObject, 'Xdata',[time(1) time(1) time(2) time(2) time(1)] ,'Ydata', [a(3) a(4) a(4) a(3) a(3)], 'visible','on');
	elseif any(hObject == [handles.XAxis, handles.YAxis, handles.ZAxis])
		updateView4DSliceInterstect(hObject, eventdata, handles);
	end
end

% --- Executes on scroll wheel click while the figure is in focus.
function ScrollWheel(hObject, eventdata)
handles = guidata(hObject);
if ~getappdata(handles.View4DFigure,'ControlLock')% clicking is not disabled?
	hObject = hittest(handles.View4DFigure); 
	if strcmpi(get(hObject,'type'),'Figure')
		return
	end
	while ~strcmpi(get(hObject,'type'),'Axes')
		hObject = get(hObject,'parent');
	end
% 	hObject = get(handles.View4DFigure,'CurrentAxes');
	switch hObject
		case handles.XAxis
			pos = getappdata(hObject,'Slice');
			s = axis(handles.ZAxis);
			pos = min(floor(s(2)), max(1, pos+eventdata.VerticalScrollAmount*eventdata.VerticalScrollCount) );
			setappdata(hObject,'Slice',pos);
		case handles.YAxis
			pos = getappdata(hObject,'Slice');
			s = axis(handles.ZAxis);
			pos = min(floor(s(4)), max(1, pos+eventdata.VerticalScrollAmount*eventdata.VerticalScrollCount) );
			setappdata(hObject,'Slice',pos);
		case handles.ZAxis
			pos = getappdata(hObject,'Slice');
			s = axis(handles.YAxis);
			pos = min(floor(s(2)), max(1, pos+eventdata.VerticalScrollAmount*eventdata.VerticalScrollCount) );
			setappdata(hObject,'Slice',pos);
		otherwise
			return
	end
	updateView4DSlices(handles);

	% Additional callback after pointer move
	if ~isempty(getappdata(handles.View4DFigure,'PointerCallback'))
		feval(getappdata(handles.View4DFigure,'PointerCallback'),handles.View4DFigure,'',handles)
	end
end



% SETPULLDOWNVALUE - sets the value in a pulldown menu.
%
% setPullDownValue(h,val) - set the value of the object h to the value
% specified by val. val can be:
%  - an index into the pulldown
%  - the string entry of the pull down
% if no match is found, or the value is out of range, entry 1 is set as the
% default value and the requested value is stored in the 'UserData' object
% property.
function setPullDownValue(h,val)

values = get(h,'String'); % All possible entries
% A string?
if ischar(val)
	i = find(strcmpi(values,val));
	if isempty(i) % String does not exist in pulldown?
		ind = str2double(val); % is string an index to the pulldown
		if ~isempty(ind) && ind>=1 && ind<=length(values) % that is in range
			set(h,'Value',ind)
			set(h,'UserData',''); % no "failed attempt value"
		else
			set(h,'Value',1); % Set default entry
			set(h,'UserData',val); % keep the "failed attempt value"
		end
	else
		set(h,'Value',i(1));			
		set(h,'UserData',''); % no "failed attempt value"
	end
else % value is a number
	if ~isempty(val) && val>=1 && val<=length(values) % that is in range
		set(h,'Value',val);		
		set(h,'UserData',''); % no "failed attempt value"
	else
		set(h,'Value',1); % Set default entry		
		set(h,'UserData',val); % keep the "failed attempt value"
	end
end