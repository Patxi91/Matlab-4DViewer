function updateView4DSlices(handles)
% updateView4DSlices - updates the slices display in View4D figure.
%
% Usage:
% ------
% updateView4DSlices(handles)
%
% See also: View4D, View4DFrameSelectionChange

%By Ran Klein, University of Ottawa Heart Institute, 2005


if nargin<1
	handles = guidata(gcf);
elseif ~isstruct(handles)
	handles = guidata(handles);
end

x = getappdata(handles.XAxis,'Slice');
y = getappdata(handles.YAxis,'Slice');
z = getappdata(handles.ZAxis,'Slice');

vol = getappdata(handles.View4DFigure,'SummedData');
pixval = vol(x,y,z);
if ~get(handles.ISScale,'value') 
	maxval = str2double(get(handles.MaxIntEdit,'string'));
	set(handles.StatusBar,'string',['(' num2str(x) ',' num2str(y) ',' num2str(z) ') Pixel Value (relative): ' num2str(pixval) ' (' num2str(100*pixval/maxval) '%)  Contrast: ' num2str(100*(maxval-pixval)/maxval) '%']);
else
	set(handles.StatusBar,'string',['(' num2str(x) ',' num2str(y) ',' num2str(z) ') Pixel Value: ' num2str(pixval)]);
end
s = size(vol);

if get(handles.MIPCheckbox,'Value')
	imgx = reshape(max(vol,[],1),[s(2),s(3)])';
	imgy = reshape(max(vol,[],2),[s(1),s(3)]);
	imgz = reshape(max(vol,[],3),[s(1),s(2)]);
else
	imgx = reshape(vol(x,:,:),[s(2),s(3)])';
	imgy = reshape(vol(:,y,:),[s(1),s(3)]);
	imgz = reshape(vol(:,:,z),[s(1),s(2)]);
end

pd = getappdata(handles.View4DFigure,'PixelDimensions');
if ~any(strcmpi(get(get(handles.XAxis,'children'),'type'),'image')) % first time that images are created
	hl = zeros(3,2);
	ah = [handles.XAxis, handles.YAxis, handles.ZAxis];
	titles = getappdata(handles.View4DFigure,'axisTitles');
	for i=1:length(ah)
		if ah(i)==handles.XAxis
			hi = imagesc(imgx,'parent',handles.XAxis);
			set(hi,'ydata',get(hi,'ydata')+0.00001);
			daspect(ah(i),1./[pd(1) pd(3) 1]);
			hl(2,1) = line([y y],[1 s(3)],'parent',ah(i));
			hl(3,1) = line([1 s(2)],[z z],'parent',ah(i));			
		elseif ah(i)==handles.YAxis
			hi = imagesc(imgy,'parent',handles.YAxis);
			set(hi,'ydata',get(hi,'ydata')+0.00001);
			daspect(ah(i),1./[pd(3) pd(2) 1]);
			hl(1,1) = line([1 s(3)],[x x],'parent',ah(i));
			hl(3,2) = line([z z],[1 s(1)],'parent',ah(i));
		else
			hi = imagesc(imgz,'parent',handles.ZAxis);
			set(hi,'ydata',get(hi,'ydata')+0.00001);
			daspect(ah(i),1./[pd(1) pd(2) 1]);
			hl(1,2) = line([1 s(2)],[x x],'parent',ah(i));
			hl(2,2) = line([y y],[1 s(1)],'parent',ah(i));
		end
		axis(ah(i),'off');
		title(ah(i),titles{i})

		set([ah(i), hi],'ButtonDownFcn','View4D(''Axis_ButtonDownFcn'',gcbo,[],guidata(gcbo))');
	end
	CM = uicontextmenu('parent',handles.View4DFigure,'callback',@CMUpdate);
	CCM = uimenu(CM,'Label','Color','Callback',@ColorMUpdate);
	uimenu(CCM,'Label','White','ForegroundColor','w','Callback',@SetColor);
	uimenu(CCM,'Label','Black','ForegroundColor','k','Callback',@SetColor);
	uimenu(CCM,'Label','Blue','ForegroundColor','b','Callback',@SetColor);
	uimenu(CCM,'Label','Red','ForegroundColor','r','Callback',@SetColor);
	set(hl,'color','w','linestyle','--','ButtonDownFcn','View4D(''Axis_ButtonDownFcn'',gcbo,[],guidata(gcbo))','UIContextMenu',CM);
	setappdata(handles.View4DFigure,'SliceLines',hl);
else
	hl = getappdata(handles.View4DFigure,'SliceLines');
	set(findobj(handles.XAxis,'type','image'),'CData',imgx);
	set(findobj(handles.YAxis,'type','image'),'CData',imgy);
	set(findobj(handles.ZAxis,'type','image'),'CData',imgz);
	set(hl(1,1),'Ydata',[x x]);
	set(hl(1,2),'Ydata',[x x]);
	set(hl(2,1),'Xdata',[y y]);
	set(hl(2,2),'Xdata',[y y]);
	set(hl(3,1),'Ydata',[z z]);
	set(hl(3,2),'Xdata',[z z]);
end

if get(handles.UScale,'value')
	clim = str2num(get(handles.MaxIntEdit,'String'));
	if isempty(clim)
		clim = getappdata(handles.GDScale,'Scale');
	else
		clim = [0 clim];
	end
	clim = fixCLim(clim);
	set(handles.XAxis,'CLim',clim);
	set(handles.YAxis,'CLim',clim);
	set(handles.ZAxis,'CLim',clim);
elseif get(handles.GDScale,'value')
	clim = fixCLim(getappdata(handles.GDScale,'Scale'));
	set(handles.MaxIntEdit,'String',num2str(clim(2)));
	set(handles.XAxis,'CLim',clim);
	set(handles.YAxis,'CLim',clim);
	set(handles.ZAxis,'CLim',clim);
elseif get(handles.GSScale,'value')
	clim = fixCLim(getappdata(handles.GSScale,'Scale'));
	set(handles.MaxIntEdit,'String',num2str(clim(2)));
	set(handles.XAxis,'CLim',clim);
	set(handles.YAxis,'CLim',clim);
	set(handles.ZAxis,'CLim',clim);
else % ISScale
	set(handles.MaxIntEdit,'String','');
	set(handles.XAxis,'CLim',fixCLim([0 max(max(squeeze(vol(x,:,:))))]));
	set(handles.YAxis,'CLim',fixCLim([0 max(max(squeeze(vol(:,y,:))))]));
	set(handles.ZAxis,'CLim',fixCLim([0 max(max(squeeze(vol(:,:,z))))]));
end

%% Contours
contours = getappdata(handles.View4DFigure,'Contour');
if ~isempty(contours)
	for ci=1:length(contours)
		contour = contours{ci};
		
		[X, Z] = interpMesh(contour.Y, contour.X, contour.Z, x,contour.Type);
		hc = findobj(handles.XAxis,'tag',['Contour' num2str(ci)]);
		if isempty(hc)
			hold(handles.XAxis,'on');
			hc = plot(handles.XAxis,X,Z,contour.LineStyle);
			daspect(handles.XAxis,1./[pd(2) pd(3) 1]);
			set(hc,'tag',['Contour' num2str(ci)],'HitTest','off');
		else
			set(hc,'Xdata',X,'Ydata',Z);
		end
		
		[Z, Y] = interpMesh(contour.X, contour.Z, contour.Y, y,contour.Type);
		hc = findobj(handles.YAxis,'tag',['Contour' num2str(ci)]);
		if isempty(hc)
			hold(handles.YAxis,'on');
			hc = plot(handles.YAxis,Z,Y,contour.LineStyle);
			daspect(handles.YAxis,1./[pd(3) pd(1) 1]);
			set(hc,'tag',['Contour' num2str(ci)],'HitTest','off');
		else
			set(hc,'Xdata',Z,'Ydata',Y);
		end
		
		[X, Y] = interpMesh(contour.Z, contour.X, contour.Y, z,contour.Type);
		hc = findobj(handles.ZAxis,'tag',['Contour' num2str(ci)]);
		if isempty(hc)
			hold(handles.ZAxis,'on');
			hc = plot(handles.ZAxis,X,Y,contour.LineStyle);
			daspect(handles.ZAxis,1./[pd(1) pd(2) 1]);
			set(hc,'tag',['Contour' num2str(ci)],'HitTest','off');
		else
			set(hc,'Xdata',X,'Ydata',Y);
		end
		
	end
end

%% Time activity curve

time = getappdata(handles.View4DFigure,'TimePoints');
if ~isempty(time);
	vol = getappdata(handles.View4DFigure,'RawData');
	ht = get(handles.TAxis,'children');
	if ~any(strcmpi(get(ht,'type'),'line'))
		tac = getappdata(handles.TAxis,'TAC');
		leg = [];
		if ~isempty(tac)
			style = {'--b','--r','--g','--c'};
			if iscell(tac)
				for i = 1:size(tac,1)
					if size(tac,2)>1 && ~isempty(tac{i,2})
						plot(handles.TAxis,time,tac{i,1},tac{i,2});
					else
						plot(handles.TAxis,time,tac{i,1},style{i,2});
					end
					hold(handles.TAxis,'on')
				end
				if size(tac,2)>2
					leg = [tac(:,3);'User selected pixel'];
				end
			else
				plot(handles.TAxis,time,tac,style);
				hold(handles.TAxis,'on')
			end
		end
		vol = squeeze(vol(x,y,z,:));
		ht = plot(handles.TAxis,time,vol,'k','linewidth',2.0);
		set([ht handles.TAxis],'buttondownfcn',@timeDrag);
		setappdata(handles.View4DFigure,'TimeLine',ht);
		setappdata(ht,'Operation','User Selected Pixel');
		cmenu = uicontextmenu('parent',handles.View4DFigure);
		cb = 'setappdata(get(gcbo,''UserData''),''Operation'',get(gcbo,''Label'')); updateView4DSlices';
		uimenu(cmenu, 'Label', 'User Selected Pixel', 'UserData', ht, 'callback', cb);
		uimenu(cmenu, 'Label', 'Max', 'UserData', ht, 'callback', cb);
		uimenu(cmenu, 'Label', 'Mean', 'UserData', ht, 'callback', cb);
		uimenu(cmenu, 'Label', 'Median', 'UserData', ht, 'callback', cb);
		uimenu(cmenu, 'Label', 'RMS', 'UserData', ht, 'callback', cb);
		uimenu(cmenu, 'Label', 'Standard-Deviation', 'UserData', ht, 'callback', cb);
		set(ht,'UIContextMenu',cmenu);
		xlabel(handles.TAxis,getappdata(handles.View4DFigure,'TimeUnits'));
		ylabel(handles.TAxis,getappdata(handles.View4DFigure,'Units'));
		if ~isempty(leg)
			setappdata(handles.TAxis,'Legend',legend(handles.TAxis,leg));
		end
	else
		ht = getappdata(handles.View4DFigure,'TimeLine');
		switch getappdata(ht,'Operation')
			case 'User Selected Pixel',	vol = squeeze(vol(x,y,z,:));
			case 'Max', 
				s = size(vol);
				vol = squeeze(nanmax(reshape(vol,[prod(s(1:3)) s(4)]),[],1));
			case 'Mean',
				s = size(vol);
				vol = squeeze(nanmean(reshape(vol,[prod(s(1:3)) s(4)]),1));
			case 'Median',
				s = size(vol);
				vol = squeeze(nanmedian(reshape(vol,[prod(s(1:3)) s(4)])));
			case 'RMS',
				s = size(vol);
				vol = reshape(vol,[prod(s(1:3)) s(4)]);
				vol = squeeze(sqrt(nansum(vol,1).^2)./sum(~isnan(vol),1));
			case 'Standard-Deviation',
				s = size(vol);
				vol = squeeze(nanstd(reshape(vol,[prod(s(1:3)) s(4)]),[],1));
		end
		lh = findobj(get(getappdata(handles.TAxis,'Legend'),'children'),'flat','type','text');
		if ~isempty(lh)
			set(lh(1),'tag',getappdata(ht,'Operation'),'string',getappdata(ht,'Operation'));
		end
		set(ht,'YData',vol);
	end
	title(handles.TAxis,['Time-Activity Curve (', num2str(x) ',' num2str(y) ',' num2str(z) ')']);
	ph = getappdata(handles.TAxis,'TimePatch');
	a = axis(handles.TAxis);
	if get(handles.Other,'Value') 
		if ~isempty(ph)
			set(ph,'Visible','off');
		end
	else
		if 1
			[frame_len, frame_start] = mst2frameTimes(time,1);
			starti = round(get(handles.StartFrameSlider,'Value'));
			if get(handles.SingleFrame,'Value')
				endi = starti;
			else
				endi = round(get(handles.EndFrameSlider,'Value'));
			end
			time = [frame_start(starti) frame_start(endi)+frame_len(endi)];
		else
			if get(handles.SingleFrame,'Value')
				time = time(round(get(handles.StartFrameSlider,'Value'))) * ones(1,2);
			else
				time = [time(round(get(handles.StartFrameSlider,'Value'))) time(round(get(handles.EndFrameSlider,'Value')))];
			end
		end
		if isempty(ph) || ~ishandle(ph)
			ph = patch([time(1) time(1) time(2) time(2) time(1)] ,[a(3) a(4) a(4) a(3) a(3)], [0.3 0.3 1] ,'parent', handles.TAxis, 'EdgeColor', [0 0 1],'buttondownfcn',@timeDrag);
			setappdata(handles.TAxis,'TimePatch',ph);
		else
			set(ph, 'Xdata',[time(1) time(1) time(2) time(2) time(1)] ,'Ydata', [a(3) a(4) a(4) a(3) a(3)], 'visible','on');
		end
	end
end
	



%% Context menu functions
function CMUpdate(hObject, event, handles)

function ColorMUpdate(hObject, event, handles)
hl = getappdata(gcf,'SliceLines');
C = get(hl(1,1),'Color');
h = get(hObject,'children');
for i = 1:length(h)
	if isequal(get(h(i),'ForeGroundColor'),C)
		set(h(i),'Check','on');
	else
		set(h(i),'Check','off');
	end
end


function SetColor(hObject,event,handles)
set(getappdata(gcf,'SliceLines'),'Color',get(hObject,'ForeGroundColor'));

function timeDrag(hObject,event,handles)
handles = guidata(gcf);
if ~getappdata(handles.View4DFigure,'ControlLock') % clicking is not diabled?
	if ~strcmpi(get(handles.View4DFigure,'SelectionType'),'alt')
		pos = get(handles.TAxis,'CurrentPoint'); pos = pos(1, 1:2);
		ph = getappdata(handles.TAxis,'TimePatch');
		setappdata(handles.View4DFigure,'CurrentObject',ph);
		time = getappdata(handles.View4DFigure,'TimePoints');
		if pos(1)>time(end)
			time = time(end);
		elseif pos(1)<time(1)
			time = time(1);
		else
			time = interp1(time, time, pos(1),'nearest');
		end
		set(ph,'Userdata',time);
	end
end

function clim = fixCLim(clim)
if clim(1)>=clim(2)
	clim(2) = clim(1)+1;
end