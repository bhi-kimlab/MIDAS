from pylab import *
import sys

color_map=sys.argv[1] #autumn, hsv, ..http://matplotlib.org/examples/color/colormaps_reference.html
color_num=int(sys.argv[2])

cmap = cm.get_cmap(color_map, color_num)
for i in range(cmap.N):
	rgb = cmap(i)[:3]
	print(matplotlib.colors.rgb2hex(rgb))
