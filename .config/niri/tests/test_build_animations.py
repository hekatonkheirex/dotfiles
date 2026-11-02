import importlib.util, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("b", root / "scripts/build-animations.py"); b = importlib.util.module_from_spec(spec); spec.loader.exec_module(b)
for o, c in [("-", "-"), ("soft-warp-fade", "snap"), ("dissolve", "smoke")]:
    out = b.render(o, c)
    assert "@OPEN@" not in out and "@CLOSE@" not in out
    assert out.count("custom-shader") == (o != "-") + (c != "-")
    assert out.count("{") == out.count("}"), (o, c)
print("ok")
