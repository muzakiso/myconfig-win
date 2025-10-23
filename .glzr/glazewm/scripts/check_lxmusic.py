import subprocess
import psutil

# 检查进程是否运行
lx_running = any(
    "lx-music-desktop" in p.name().lower() for p in psutil.process_iter(["name"])
)

if not lx_running:
    subprocess.Popen(["lx-music-desktop"])
