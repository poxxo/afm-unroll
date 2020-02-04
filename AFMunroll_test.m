%seq = AFMunroll( 'inop_4p88Hz_20000.ibw', '', 'FrameUp');
seq = AFMunroll( 'inop_0p98Hz0000.ibw', 'UserIn0', 'FrameUp');
fs = 2*0.98*4096;
t = linspace(0, size(seq, 2)/fs, size(seq, 2));

plot(t, seq(1, :));

%%
[seq, t] = AFMunroll('inop_0p98Hz0000.ibw', {'UserIn0'}, 'FrameUp', 0.98, 4096);
plot(t, seq(1, :));
