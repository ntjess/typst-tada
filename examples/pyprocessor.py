from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
from tempfile import TemporaryDirectory

DEFAULT_LABEL = "py-code"


def get_python_blocks(file: str | Path, label: str | None = None):
    """
    Retrieves the python code blocks from a typ file requested to be run based on their
    label.

    Parameters
    ----------
    file:
        The typst file to be queried
    label:
        The label of the blocks to be retrieved. Defaults to "py-code"
    concatenate:
        Whether to concatenate the blocks into a single python runnable string. Otherwise,
        returns an array of individual code blocks found in the file.
    """
    if label is None:
        label = DEFAULT_LABEL
    cmd = (
        f"typst-ts-cli query"
        f' --entry "{Path(file).resolve()}"'
        f' --selector "<{label}>"'
        f" --field value"
        f" --format json"
    )
    workspace_dir = os.getcwd()
    result = json.loads(
        subprocess.check_output(cmd, cwd=workspace_dir, shell=True, text=True)
    )
    return result


def _format_text_for_cell(text):
    """
    Formats text to be inserted into a cell. This is a workaround for the fact that
    raw formatting can't be applied to content, so explicitly surround in newlines
    and triple quotes instead.
    """
    if not text.strip():
        return ""
    if text[0] != "\n":
        text = "\n" + text
    if text[-1] != "\n":
        text += "\n"
    return f"```console{text}```"


def replace_output_blocks(
    file: str | Path, outputs: list[str], output_locations: list[dict], backup=True
):
    """
    Replaces the output blocks in a typst file with the outputs from a python session.

    Parameters
    ----------
    file:
        The typst file to be queried
    outputs:
        A list of outputs to be inserted into the typst file
    output_locations:
        A list of {start_row: int, start_col: int, end_row: int, end_col: int} objects
        representing the locations of the output blocks in the typst file
    """
    file = Path(file)
    with open(file) as f:
        lines = f.readlines()
    if backup:
        shutil.copy(file, file.with_suffix(file.suffix + ".bak"))
    # Reverse the order of the outputs and locations so earlier location indexes
    # still make sense
    for text, location in list(zip(outputs, output_locations))[::-1]:
        start_row, start_col, end_row, end_col = (
            location[key] for key in ["start_row", "start_col", "end_row", "end_col"]
        )
        text = _format_text_for_cell(text)
        lines[start_row - 1] = (
            lines[start_row - 1][: start_col + 1]
            + text
            + lines[end_row - 1][end_col - 1 :]
        )
        lines = lines[:start_row] + lines[end_row:]

    with open(file, "w") as f:
        f.write("".join(lines))


def exec_blocks_and_capture_outputs(blocks: list[str], print_blocks=False):
    """
    Evaluates a list of python code blocks in a single python session. stdout from each
    block evaluation is separately captured.

    Parameters
    ----------
    blocks:
        A list of python code blocks to be evaluated

    Returns
    -------
    A list of stdout outputs from each block evaluation
    """
    outputs = []
    for block in blocks:
        if print_blocks:
            print(block)
        with redirect_stdout(StringIO()) as f:
            exec(block, globals())
            outputs.append(f.getvalue())
    return outputs


def main(file):
    blocks = get_python_blocks(file)
    outputs = exec_blocks_and_capture_outputs(blocks)
    output_locations = get_output_locations(file)
    replace_output_blocks(file, outputs, output_locations)


def main_cli():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    args = parser.parse_args()

    main(args.file)


if __name__ == "__main__":
    main_cli()
