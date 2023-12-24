from __future__ import annotations

import json
import os
import sys
import subprocess
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path

import logging


class CodeRunner:
    def __init__(self, workspace_dir: str | Path):
        self.workspace_dir = Path(workspace_dir).resolve()
        self.logger = logging.getLogger(__name__)

        self.cache_file = cache_file = self.workspace_dir / ".coderunner.json"
        if not cache_file.exists():
            self.workspace_cache = {}
            self.cache_file.write_text("{}")
        else:
            with open(cache_file, "r") as f:
                self.workspace_cache = json.load(f)

    def get_cache_key(self, file: str | Path):
        file = Path(file).resolve()
        if self.workspace_dir not in file.parents:
            raise ValueError(f"File {file} is not in workspace {self.workspace_dir}")
        return file.relative_to(self.workspace_dir).as_posix()

    def get_cache_value(self, file: str | Path, return_key=False):
        rel_file = self.get_cache_key(file)
        if rel_file not in self.workspace_cache:
            self.workspace_cache[rel_file] = {}
        out = self.workspace_cache[rel_file].copy()
        if return_key:
            return out, rel_file
        return out

    def update_cache(self, file: str | Path, label: str, outputs: list[str]):
        file_cache, key = self.get_cache_value(file, return_key=True)
        file_cache[label] = outputs

        self.workspace_cache[key][label] = outputs

    def save_cache(self):
        with open(self.cache_file, "w") as f:
            json.dump(self.workspace_cache, f)

    def get_labeled_blocks(self, file: str | Path, label: str):
        """
        Retrieves the python code blocks from a typ file requested to be run based on their
        label.

        Parameters
        ----------
        file:
            The typst file to be queried
        label:
            The label of the blocks to be retrieved
        concatenate:
            Whether to concatenate the blocks into a single python runnable string. Otherwise,
            returns an array of individual code blocks found in the file.
        """
        workspace_dir = os.getcwd()
        cmd = (
            f"typst query"
            f' "{Path(file).resolve()}"'
            f' "<{label}>"'  # Selector
            f" --field value"
            f" --format json"
            f" --root {workspace_dir}"
        )
        self.logger.debug(f"Running command: {cmd}")
        workspace_dir = os.getcwd()
        result = json.loads(subprocess.check_output(cmd, shell=True, text=True))
        return result

    def exec_blocks_and_capture_outputs(self, blocks: list[str]):
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
            with redirect_stdout(StringIO()) as f:
                self.logger.debug(f"Executing block:\n{block}")
                exec(block, globals())
                out = f.getvalue()
                self.logger.debug(f"Block output: {out}")
                outputs.append(out)
        return outputs

    def run(self, typst_file: str | Path, label: str, save_cache=True):
        blocks = self.get_labeled_blocks(typst_file, label=label)
        outputs = self.exec_blocks_and_capture_outputs(blocks)
        self.update_cache(typst_file, label, outputs)
        if save_cache:
            self.save_cache()


def main_cli():
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("file")
    args = parser.parse_args()

    runner = CodeRunner(os.getcwd())
    # runner.logger.setLevel("DEBUG")
    runner.logger.addHandler(logging.StreamHandler(sys.stdout))
    runner.run(args.file, label="python", save_cache=True)


if __name__ == "__main__":
    main_cli()
