function [width] = fwhm(x,y,varargin)

% function width = fwhm(x,y)
%
% Full-Width at Half-Maximum (FWHM) of the waveform y(x)
% and its polarity.
% The FWHM result in 'width' will be in units of 'x'
%
%
% Rev 1.2, April 2006 (Patrick Egan)
% Rev 1.3, February 2018 (Bondarenko YV)

if length(varargin) == 1
    do_console_output = varargin{1};
else
    do_console_output = false;
end

y = y / max(y);
N = length(y);
lev50 = 0.5;
if y(1) < lev50                  % find index of center (max or min) of pulse
    [~,centerindex]=max(y);
    Pol = +1;
    if do_console_output
        disp('Pulse Polarity = Positive')
    end
else
    [~,centerindex]=min(y);
    Pol = -1;
    if do_console_output
        disp('Pulse Polarity = Negative')
    end
end
i = 2;
while sign(y(i)-lev50) == sign(y(i-1)-lev50)
    i = i+1;
end                                   %first crossing is between v(i-1) & v(i)
interp = (lev50-y(i-1)) / (y(i)-y(i-1));
tlead = x(i-1) + interp*(x(i)-x(i-1));
i = centerindex+1;                    %start search for next crossing at center
while ((sign(y(i)-lev50) == sign(y(i-1)-lev50)) && (i <= N-1))
    i = i+1;
end
if i ~= N
    Ptype = 1;  
    if do_console_output
        disp('Pulse is Impulse or Rectangular with 2 edges')
    end
    interp = (lev50-y(i-1)) / (y(i)-y(i-1));
    ttrail = x(i-1) + interp*(x(i)-x(i-1));
    width = ttrail - tlead;
else
    Ptype = 2; 
    if do_console_output
        disp('Step-Like Pulse, no second edge')
    end
    ttrail = NaN;
    width = NaN;
end
