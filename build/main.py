import subprocess

from parsing import resolve_includes
from os import chdir, system
import ahk

root = subprocess.run(["git", "rev-parse", "--show-toplevel"], shell=True, capture_output=True, text=True).stdout.strip()
chdir(root)
if __name__ == "__main__":
    resolve_includes("src/gutils.ahk", "gutils.ahk")
    ahk.run("test/gutils.test.ahk")
