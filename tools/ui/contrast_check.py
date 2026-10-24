def luminance(color):
    values=[int(color[i:i+2],16)/255 for i in (0,2,4)]
    values=[v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values]
    return sum(a*b for a,b in zip(values,[.2126,.7152,.0722]))
for foreground in ['f6eedb','f1cb7b']:
    for background in ['141b25','29313d']:
        ratio=(luminance(foreground)+.05)/(luminance(background)+.05)
        assert ratio>=4.5,(foreground,background,ratio)
        print(f'{foreground}/{background}: {ratio:.2f}:1')
