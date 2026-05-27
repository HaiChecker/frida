# x-frida

Stealth-patched Frida build for bypassing RiskEngine and similar Android anti-tampering SDKs.

## Quick Install

```bash
# Install from release wheels
pip install x-frida
pip install x-frida-tools
```

Or download wheels from [Releases](../../releases) and install locally:

```bash
pip install x_frida-*.whl
pip install x_frida_tools-*.whl
```

## Android Server Deployment

```bash
# Push server to device (renamed to media.codec for stealth)
adb push x-frida-server-android-arm64 /data/local/tmp/media.codec
adb shell "su -c 'chmod 755 /data/local/tmp/media.codec && /data/local/tmp/media.codec &'"
```

## Usage

```bash
# Connect to stealth server (port 52173)
x-frida -H 127.0.0.1:52173 -p <PID> -l script.js
x-frida-ps -H 127.0.0.1:52173
x-frida-trace -H 127.0.0.1:52173 -p <PID> -i "open"
```

## What's Different

| Feature | Original Frida | x-frida |
|---------|---------------|---------|
| Server name | frida-server | media.codec |
| Helper name | frida-helper | media.extractor |
| Gadget name | frida-gadget.so | libhwui.so |
| Port | 27042 | 52173 |
| Thread names | frida-main-loop, gum-js-loop | HwBinder:1, Signal Catcher |
| memfd name | (anonymous) | jit-cache |
| /proc maps | frida-agent-*.so | no literal pool traces |
| Auth | none | magic bytes (deadbeefcafebabe) |

## Build from Source

```bash
# Android server
./configure --host=android-arm64 \
  --with-stealth-memfd-name=jit-cache \
  --with-stealth-thread-js="Signal Catcher" \
  --with-stealth-server-name=media.codec \
  --with-stealth-helper-name=media.extractor \
  --with-stealth-gadget-name=libhwui \
  --with-stealth-port=52173 \
  --with-stealth-thread-main="HwBinder:1" \
  --with-stealth-thread-gadget=RenderThread \
  --with-stealth-server-dir=com.android.providers.media \
  --with-stealth-magic=deadbeefcafebabe
make
```

## Learn more

Have a look at Frida's [documentation](https://frida.re/docs/home/).
