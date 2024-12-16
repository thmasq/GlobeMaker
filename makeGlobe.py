import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
import numpy as np
import pyproj
import os
import sys
import getopt
from PIL import Image
import cartopy.io.shapereader as shpreader
from cartopy.mpl.patch import geos_to_path
from shapely.geometry import Polygon, box

def getRhumb(startlong, startlat, endlong, endlat, nPoints):
    # calculate distance between points
    g = pyproj.Geod(ellps='WGS84')

    # calculate line string along path with segments <= 1 km
    lonlats = g.npts(startlong, startlat, endlong, endlat, nPoints)

    # npts doesn't include start/end points, so prepend/append them and return
    lonlats.insert(0, (startlong, startlat))
    lonlats.append((endlong, endlat))
    return lonlats

def makeGore(central_meridian, gore_width, number, width, gore_stroke):
    # Create a custom sinusoidal projection centered on the gore's central meridian
    gore_proj = ccrs.Sinusoidal(central_longitude=central_meridian)
    plate_proj = ccrs.PlateCarree()
    
    # Set up the figure
    plt.figure(figsize=(width/100, (width/2)/100), dpi=100)
    ax = plt.subplot(1, 1, 1, projection=gore_proj)
    
    # Define the extent (full latitudinal range, rectangular box for now)
    halfWidth = gore_width / 2
    ax.set_extent([central_meridian - halfWidth, central_meridian + halfWidth, -90, 90], crs=plate_proj)
    
    # Add land and coastlines
    ax.add_feature(cfeature.LAND, facecolor='black', edgecolor='none')
    ax.add_feature(cfeature.COASTLINE, edgecolor='black', linewidth=gore_stroke/2)
    
    clipping_mask = box(central_meridian - halfWidth, -90, central_meridian + halfWidth, 90)

    ax.add_geometries([clipping_mask], crs=plate_proj, facecolor='white', edgecolor='none', zorder=3)

    # Remove axes and save
    plt.axis('off')
    plt.tight_layout(pad=0)
    plt.savefig(f"tmp/gore{number}.png", bbox_inches='tight', pad_inches=0, transparent=False, facecolor='white')
    plt.close()

def main(argv):
    # make sure the tmp folder exists
    if not os.path.exists("tmp"):
        os.makedirs("tmp")

    # set defaults
    GORE_WIDTH_PX = 500
    GORE_WIDTH_DEG = 60
    OUT_PATH = "globe.png"
    GORE_OUTLINE_WIDTH = 4

    # read in arguments
    try:
        opts, args = getopt.getopt(argv, "hp:d:g:o:")
    except getopt.GetoptError:
        print('python makeGlobe.py -p [GORE_WIDTH_PX] -d [GORE_WIDTH_DEGREES] -g [GORE_OUTLINE_WIDTH] -o [OUT_PATH]')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print('python makeGlobe.py -p [GORE_WIDTH_PX] -d [GORE_WIDTH_DEGREES] -g [GORE_OUTLINE_WIDTH] -o [OUT_PATH]')
            sys.exit()
        elif opt == '-p':
            GORE_WIDTH_PX = int(arg)
        elif opt == '-d':
            GORE_WIDTH_DEG = int(arg)
        elif opt == '-g':
            GORE_OUTLINE_WIDTH = int(arg)
        elif opt == '-o':
            OUT_PATH = arg

    # verify values
    if GORE_WIDTH_PX < 0:
        print("invalid -p (GORE_WIDTH_PX) value: " + str(GORE_WIDTH_PX))
        print("GORE_WIDTH_DEG must be >0.")
        sys.exit(0)
    if GORE_WIDTH_DEG < 15 or GORE_WIDTH_DEG > 120 or 360 % GORE_WIDTH_DEG > 0:
        print("invalid -d (GORE_WIDTH_DEG) value: " + str(GORE_WIDTH_PX))
        print("GORE_WIDTH_DEG must be >=15, <=120 and multiply into 360.")
        print("Valid numbers include: 120, 90, 60, 30, 20, 15")
        sys.exit(0)

    # how many gores?
    I = 360 // GORE_WIDTH_DEG

    # make a test gore to see how big it is
    makeGore(0, GORE_WIDTH_DEG, 666, GORE_WIDTH_PX, 0)
    im666 = Image.open("tmp/gore666.png")
    w, h = im666.size

    # make gores and join them together into a single image
    im = Image.new("RGB", (GORE_WIDTH_PX * I, h), "white")
    for i in range(0, I):
        cm = -180 + (GORE_WIDTH_DEG/2) + (GORE_WIDTH_DEG * i)
        # slight adjustment to prevent wrapping
        if i == I-1:
            cm -= 0.01
        print(f"Creating gore {i} with central meridian {cm}")
        makeGore(cm, GORE_WIDTH_DEG, i, GORE_WIDTH_PX, GORE_OUTLINE_WIDTH)
        im1 = Image.open(f"tmp/gore{i}.png")
        im.paste(im1, (GORE_WIDTH_PX * i, 0))

    # clean up all tmp files
    files = os.listdir("tmp")
    for f in files:
        os.remove(os.path.join("tmp", f))
    
    # export and display
    im.save(OUT_PATH)
    im.show()

if __name__ == "__main__":
    main(sys.argv[1:])
