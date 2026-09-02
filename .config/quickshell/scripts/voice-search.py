#!/usr/bin/env python3
import sys
import os
import pathlib
import tempfile
import urllib.request
import zipfile
import wave
import json

# Paths
model_dir = os.path.expanduser("~/.local/share/vosk-model")
model_zip = os.path.expanduser("~/.local/share/vosk-model.zip")

# Ensure model exists
if not os.path.exists(model_dir):
    import subprocess
    print("Vosk model not found. Downloading (approx. 40MB)...", file=sys.stderr)
    subprocess.run(["notify-send", "-a", "Voice Search Launcher", "Vosk model not found", "Downloading offline recognition model (~40MB)..."])
    model_parent = os.path.dirname(model_dir)
    os.makedirs(model_parent, mode=0o700, exist_ok=True)
    os.chmod(model_parent, 0o700)
    url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
    temporary_zip = None
    temporary_extract_dir = None
    try:
        fd, temporary_zip = tempfile.mkstemp(prefix="vosk-model.", suffix=".zip", dir=model_parent)
        os.close(fd)
        with urllib.request.urlopen(url, timeout=60) as response, open(temporary_zip, "wb") as output:
            while True:
                chunk = response.read(1024 * 1024)
                if not chunk:
                    break
                output.write(chunk)

        temporary_extract_dir = tempfile.mkdtemp(prefix=".vosk-extract-", dir=model_parent)
        extract_root = pathlib.Path(temporary_extract_dir).resolve()
        expected_root = extract_root / "vosk-model-small-en-us-0.15"
        with zipfile.ZipFile(temporary_zip, "r") as zip_ref:
            for member in zip_ref.infolist():
                member_path = pathlib.PurePosixPath(member.filename)
                if member_path.is_absolute() or ".." in member_path.parts:
                    raise ValueError(f"Unsafe model archive member: {member.filename}")
                target = (extract_root / pathlib.Path(*member_path.parts)).resolve()
                if target != extract_root and extract_root not in target.parents:
                    raise ValueError(f"Unsafe model archive member: {member.filename}")
            zip_ref.extractall(extract_root)

        if not expected_root.is_dir():
            raise ValueError("Model archive did not contain the expected directory")
        os.chmod(temporary_extract_dir, 0o700)
        os.replace(expected_root, model_dir)
    except Exception as e:
        print(f"Error downloading model: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if temporary_zip and os.path.exists(temporary_zip):
            os.remove(temporary_zip)
        if temporary_extract_dir and os.path.exists(temporary_extract_dir):
            import shutil
            shutil.rmtree(temporary_extract_dir, ignore_errors=True)

# Check audio file
if len(sys.argv) < 2:
    print("Usage: voice-search.py <audio_file.wav>", file=sys.stderr)
    sys.exit(1)

audio_path = sys.argv[1]
if not os.path.exists(audio_path):
    print(f"File not found: {audio_path}", file=sys.stderr)
    sys.exit(1)

try:
    from vosk import Model, KaldiRecognizer
except ImportError:
    print("Error: python-vosk library is not installed.", file=sys.stderr)
    sys.exit(1)

try:
    wf = wave.open(audio_path, "rb")
    if wf.getnchannels() != 1 or wf.getsampwidth() != 2 or wf.getcomptype() != "NONE":
        print("Audio file must be WAV format mono PCM.", file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f"Error opening audio file: {e}", file=sys.stderr)
    sys.exit(1)

model = Model(model_dir)
rec = KaldiRecognizer(model, wf.getframerate())

while True:
    data = wf.readframes(4000)
    if len(data) == 0:
        break
    if rec.AcceptWaveform(data):
        pass

res = json.loads(rec.FinalResult())
print(res.get("text", ""))
