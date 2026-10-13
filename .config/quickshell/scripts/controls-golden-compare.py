#!/usr/bin/env python3
"""Compare the Elena controls golden. Exit 1 if more than MAX_PIXELS differ
(a few pixels of animation/antialias noise appear between identical runs).
Historical other-style baselines are not part of the single-style contract."""
import sys
from PIL import Image, ImageChops

MAX_PIXELS = 40
a, b = sys.argv[1:3]
bad = 0
for f in ("elena.png",):
    d = ImageChops.difference(Image.open(f"{a}/{f}").convert("RGBA"), Image.open(f"{b}/{f}").convert("RGBA"))
    n = d.convert("L").point(lambda v: 255 if v else 0).histogram()[255]
    ok = n <= MAX_PIXELS
    bad += not ok
    print(f"{'ok  ' if ok else 'FAIL'} {f}: {n} px differ")
sys.exit(1 if bad else 0)
