import glob
import re
from os import path, chdir, getcwd


include_regex = re.compile(r'#include\s*(.*)[\t ]*\n', flags=re.IGNORECASE)
remove_comments = re.compile(r';#.*\n')


def _get_contents(name: str):
    with open(name, encoding="utf8") as fl:
        return fl.read()


def _resolve_include(match):
    file = match[1]
    contents = _get_contents(file)
    cleaned = include_regex.sub("", contents)
    cleaned = cleaned.replace("\uFEFF", "")
    return f'{cleaned}\n\n'


def resolve_includes(s_filename: str, t_filename: str):
    old_dir = getcwd()
    try:
        contents = _get_contents(s_filename)
        m_contents = remove_comments.sub("", contents)
        script_dir = path.split(s_filename)[0]
        chdir(script_dir)
        m_contents = include_regex.sub(_resolve_include, m_contents)
        chdir(old_dir)
        with open(t_filename, mode="w", encoding="utf8") as t_file:
            t_file.write(m_contents)
            t_file.flush()
        print(f'\n* Wrote to {t_filename}')
    finally:
        chdir(old_dir)
