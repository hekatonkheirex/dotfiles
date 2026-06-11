#!/usr/bin/env python3
import sys
import os
import urllib.request
import zipfile
import wave
import json

# Paths
model_dir = os.path.expanduser("~/.config/quickshell/resources/vosk-model")
model_zip = os.path.expanduser("~/.config/quickshell/resources/vosk-model.zip")

# Ensure model exists
if not os.path.exists(model_dir):
    print("Vosk model not found. Downloading (approx. 40MB)...", file=sys.stderr)
    os.makedirs(os.path.dirname(model_dir), exist_ok=True)
    url = "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
    try:
        urllib.request.urlretrieve(url, model_zip)
        with zipfile.ZipFile(model_zip, 'r') as zip_ref:
            zip_ref.extractall(os.path.dirname(model_dir))
        # Rename the extracted folder to vosk-model
        extracted_name = os.path.join(os.path.dirname(model_dir), "vosk-model-small-en-us-0.15")
        os.rename(extracted_name, model_dir)
        if os.path.exists(model_zip):
            os.remove(model_zip)
    except Exception as e:
        print(f"Error downloading model: {e}", file=sys.stderr)
        sys.exit(1)

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
