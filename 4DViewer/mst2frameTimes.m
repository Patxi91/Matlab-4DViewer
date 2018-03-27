% mst2frameTimes - converts mean sample times to frame length and frame
% start times.
% Assumes that frame 1 starts at time 0, 
%
% [frame_len, frame_start] = mst2frameTimes(mst)
% [frame_len, frame_start] = mst2frameTimes(mst,assumption) - assumes first 
% two frames are same length.
%

% By Ran Klein 30-04-2008

function [frame_length, frame_start] = mst2frameTimes(mst,assumption)
if nargin<2
	assumption = 0;
end
frame_start = zeros(size(mst)); frame_length = frame_start;
for i = 1:length(mst)
	if i==1
		if assumption==0 % time frame one starts at time zero
			frame_start(1) = 0;
			frame_length(1) = mst(1)*2;
		else % time frame one and two are equal lengths
			frame_length(1) = mst(2)-mst(1);
			frame_start(1) = mst(1)-frame_length(1)/2;
		end
	else
		frame_start(i) = (frame_start(i-1) + frame_length(i-1));
		frame_length(i) = (mst(i) - frame_start(i))*2;
	end
end