clear all; close all

f = figure;
a = axes;

anchor = [100,100];
global selector

linear = InteractiveMethod(@(x, par1, par2) par1*x+par2, {'linear, first parameter', 'linear, second parameter'}, {30,20}, {0.001, 0.001}, {120, 120});
quadratic = InteractiveMethod(@(x, par1, par2) par1*x.^2+par2, {'quadratic, first parameter', 'quadratic, second parameter'}, {20,10}, {0.001, 0.001}, {120, 120});
selector = InteractiveMethodSelector('selector', struct('linear', linear, 'quadratic', quadratic));

selector.build_gui(f, anchor, @controls_callback);

function controls_callback(~) % usage: this should be a method; use own data instead of globals (i.e. orthofig method as callback - has access to orthofig properties)   
    global selector

    x = linspace(0,10,100);
    plot(x,selector.do(x));
end
