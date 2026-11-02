#!/usr/bin/env python3
"""Usage: build-animations.py [open-shader] [close-shader]  (folder names in animations/; '-' = keep stock curve)
Renders animations/base.kdl -> animations.kdl, inlining the GLSL (niri has no shader file paths)."""
import sys, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
STOCK = {"open": 'window-open {\n        duration-ms 400\n        curve "cubic-bezier" 0.05 0.7 0.1 1.0\n    }',
         "close": 'window-close {\n        duration-ms 200\n        curve "cubic-bezier" 0.3 0.0 0.8 0.15\n    }'}

def block(kind, name):
    if name == "-":
        return STOCK[kind]
    d = root / "animations" / name
    cfg = (d / "config").read_text().strip() if (d / "config").exists() else "duration-ms 500"
    glsl = (d / f"{kind}.glsl").read_text()
    assert '"#' not in glsl, "glsl contains raw-string terminator"
    return f'window-{kind} {{\n        {cfg}\n        custom-shader r#"\n{glsl}\n"#\n    }}'

def render(open_n, close_n):
    return (root / "animations/base.kdl").read_text().replace("@OPEN@", block("open", open_n)).replace("@CLOSE@", block("close", close_n))

if __name__ == "__main__":
    o, c = (sys.argv[1:] + ["-", "-"])[:2]
    (root / "animations.kdl").write_text(render(o, c))
    print(f"open={o} close={c}")
