import os
import subprocess
from os import path, system
import winreg
from typing import Callable, List

HKCR = winreg.HKEY_CLASSES_ROOT
HKLM = winreg.HKEY_LOCAL_MACHINE
ahk_key = path.join("SOFTWARE", "AutoHotkey")
ahk_file_handler = ".ahk"
_ahk_location = ""


# WinErro
def _try_install_dir():
    with winreg.OpenKey(HKLM, ahk_key) as install_key:
        result = winreg.QueryValueEx(install_key, "InstallDir")[0]
        exe_path = path.join(result, "AutoHotkeyU64.exe")
        return exe_path


def _try_default_icon():
    with winreg.OpenKey(HKCR, ".ahk") as ftype_key:
        handler_name = winreg.QueryValueEx(ftype_key, "")[0]
    h_path = path.join(handler_name, "DefaultIcon")
    with winreg.OpenKey(HKCR, h_path) as h_key:
        h_line: str = winreg.QueryValue(HKCR, "")
    return h_line


def _try_fallbacks(*fs: Callable[[], str]):
    try:
        for f in fs:
            result = f()
            if "AutoHotkey" in result:
                return result
        raise FileNotFoundError("Couldn't find AHK location.")
    finally:
        pass


def _try_ahk_location():
    global _ahk_location
    if not _ahk_location:
        _ahk_location = _try_fallbacks(_try_install_dir, _try_default_icon, _try_ahk_location)
    return _ahk_location


def run(file: str, ahk_location=None):
    ahk_location = ahk_location or _try_ahk_location()
    dir, name = path.split(file)
    os.chdir(dir)
    p = subprocess.run([ahk_location,  '/ErrorStdOut', name], shell=True, timeout=10, text=True, check=True, encoding="utf-8")

    stdout, stderr = p.stdout, p.stderr
    x = 5
