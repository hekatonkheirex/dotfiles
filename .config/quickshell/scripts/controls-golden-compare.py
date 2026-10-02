#!/usr/bin/env python3
"""Compare two controls-golden output dirs. Exit 1 if any style differs by
more than MAX_PIXELS pixels (a few px of animation/antialias noise appears
even between identical runs)."""
import os, sys
from PIL import Image, ImageChops

MAX_PIXELS = 40
a, b = sys.argv[1:3]
bad = 0
for f in sorted(os.listdir(a)):
    d = ImageChops.difference(Image.open(f"{a}/{f}").convert("RGBA"), Image.open(f"{b}/{f}").convert("RGBA"))
    n = d.convert("L").point(lambda v: 255 if v else 0).histogram()[255]
    ok = n <= MAX_PIXELS
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {f}: {n} px differ")
sys.exit(1 if bad else 0)
