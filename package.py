import shutil
import typing as t
from pathlib import Path

from packaging.version import InvalidVersion
from packaging.version import Version as PkgVersion
import tomli

FilePath = t.Union[str, Path]

PACKAGE_PATHS = ["src", "lib.typ", "LICENSE", "README.md"]

here = Path(__file__).resolve().parent


def create_package(
    typst_packages_folder: FilePath,
    version: str,
    package_name: str,
    namespace="preview",
    exist_ok=False,
):
    try:
        PkgVersion(version)
    except InvalidVersion:
        raise ValueError(f"{version} is not a valid version")

    upload_folder = Path(typst_packages_folder) / namespace / package_name / version
    if upload_folder.exists() and not exist_ok:
        raise FileExistsError(f"{upload_folder} already exists")
    upload_folder.mkdir(parents=True, exist_ok=True)

    toml_text = here.joinpath("typst.toml").read_text()
    toml_text = toml_text.replace("{{version}}", version)
    upload_folder.joinpath("typst.toml").write_text(toml_text)
    for path in map(Path, PACKAGE_PATHS):
        if path.is_dir():
            shutil.copytree(
                here.joinpath(path), upload_folder.joinpath(path), dirs_exist_ok=True
            )
        else:
            shutil.copy(here.joinpath(path), upload_folder.joinpath(path))
    return upload_folder


if "__main__" == __name__:
    import argparse
    import os

    default_packages_folder = os.environ.get("typst_packages_folder", None)

    parser = argparse.ArgumentParser()
    parser.add_argument("toml", help="path to typst.toml", default=here / "typst.toml")
    parser.add_argument("--namespace", default="preview")
    parser.add_argument("--exist-ok", action="store_true")
    parser.add_argument("--typst-packages-folder", default=default_packages_folder)
    args = parser.parse_args()

    with open(args.toml, "rb") as ifile:
        toml_text = tomli.load(ifile)  # type: ignore
    version = toml_text["package"]["version"]
    package_name = toml_text["package"]["name"]

    folder = create_package(
        args.typst_packages_folder,
        version,
        package_name,
        namespace=args.namespace,
        exist_ok=args.exist_ok,
    )
    print(f"Created package in {folder}")
