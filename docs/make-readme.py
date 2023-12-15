# %%
import os
import re
import subprocess
from pathlib import Path

import pypandoc
import tomli

here = Path(__file__).resolve().parent
workspace = here.parent
assets_dir = workspace / "assets"
assets_dir.mkdir(exist_ok=True)
with open(workspace / "typst.toml", "rb") as f:
    version = tomli.load(f)["package"]["version"]

# %%
for file in assets_dir.glob("example-*.png"):
    file.unlink()
subprocess.run(
    f"typst c {workspace/'docs/example-extractor.typ'} {assets_dir}/example-{{n}}.png --root {workspace}".split()
)
files = sorted(assets_dir.glob("*.png"))
assert len(files) > 1, "No example images found"
# First page is bogus
files.pop(0).unlink()
# %%
files = sorted(assets_dir.glob("*.png"))
max_pad = len(str(len(files)))
for ii, file in enumerate(files):
    file.rename(assets_dir / f"example-{ii+1:0{max_pad}d}.png")

os.chdir(workspace)
contents = pypandoc.convert_file(here / "overview.typ", to="markdown", format="typst")
lines = contents.splitlines()
out_lines = []
example_number = 0
lines_iter = iter(lines)

LANG_REGEX = re.compile(r"\s*```.*example.*\b")
# ASSET_DIR = "./assets/"
# For remote:
ASSET_DIR = f"https://raw.githubusercontent.com/ntjess/typst-tada/v{version}/assets/"


def graceful_next(iterable):
    try:
        return next(iterable)
    except StopIteration:
        return None


def eat_code_block(first_line, lines_iter, out_lines):
    # Replace this language with "typst", find the end of the block
    line = re.sub(LANG_REGEX, "``` typst", first_line)
    out_lines.append(line)
    while line is not None and not re.match(r"```", line := next(lines_iter)):
        out_lines.append(line)
    out_lines.append(line)


for line in lines_iter:
    if match := re.match(LANG_REGEX, line):
        example_number += 1
        eat_code_block(line, lines_iter, out_lines)
        cur_asset = ASSET_DIR + f"example-{example_number:0{max_pad}d}.png"
        out_lines.append(f"![Example {example_number}]({cur_asset})")
    else:
        out_lines.append(line)
contents = "\n".join(out_lines)
Path(workspace / "README.md").write_text(contents)
# %%
