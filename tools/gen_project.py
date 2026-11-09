#!/usr/bin/env python3
"""Gera Malta.xcodeproj a partir das arvores Apps/Malta e Config/.

Adaptado do gerador do migalha-ios (que veio do analogik). Sem XcodeGen nem brew.
O projeto e artefato derivado: nunca editar o .pbxproj a mao; mudar
Config/*.xcconfig e rodar:

    python3 tools/gen_project.py          # regrava o projeto
    python3 tools/gen_project.py --check  # CI: falha se o projeto commitado esta velho

IDs deterministas (hash do caminho): o diff so muda quando a arvore muda.
"""

from __future__ import annotations

import hashlib
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJ = ROOT / "Malta.xcodeproj"
PACKAGE_PATH = "Packages/MaltaKit"
PACKAGE_PRODUCT = "MaltaKit"
# (nome do target, pasta do app, xcconfig do target)
TARGETS = [
    ("Malta", "Apps/Malta", "Config/Malta.xcconfig"),
]

FILE_TYPES = {
    ".swift": "sourcecode.swift",
    ".xcassets": "folder.assetcatalog",
    ".xcstrings": "text.json.xcstrings",
    ".xcprivacy": "text.xml",
    ".plist": "text.plist.xml",
    ".xcconfig": "text.xcconfig",
    ".entitlements": "text.plist.entitlements",
    ".json": "text.json",
    ".ttf": "file.ttf",
    ".txt": "text",
}
SOURCE_EXT = {".swift"}
RESOURCE_EXT = {".xcassets", ".xcstrings", ".json", ".ttf", ".txt", ".xcprivacy"}
BUNDLE_EXT = {".xcassets"}


def oid(*parts: str) -> str:
    return hashlib.md5("/".join(parts).encode("ascii")).hexdigest()[:24].upper()


def q(s: str) -> str:
    if s and all(c.isalnum() or c in "._/" for c in s):
        return s
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def git_ignored() -> set[str]:
    try:
        out = subprocess.run(["git", "-C", str(ROOT), "ls-files", "-oi", "--exclude-standard", "--directory"],
                             capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return set()
    return {line.rstrip("/") for line in out.splitlines() if line}


IGNORED = git_ignored()


def walk(rel_dir: str):
    dirs, files = [], []
    for p in sorted((ROOT / rel_dir).iterdir(), key=lambda x: x.name):
        if p.name.startswith(".") or f"{rel_dir}/{p.name}".lstrip("/") in IGNORED:
            continue
        if p.is_dir() and p.suffix not in BUNDLE_EXT:
            dirs.append(p.name)
        else:
            files.append(p.name)
    return dirs, files


def generate() -> dict[str, str]:
    objs: dict[str, str] = {}
    tree_files: dict[str, list[str]] = {}

    def file_ref(rel: str, owner: str) -> str:
        name = Path(rel).name
        fid = oid("file", rel)
        ftype = FILE_TYPES.get(Path(rel).suffix, "file")
        objs[fid] = (
            f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; "
            f"path = {q(name)}; sourceTree = \"<group>\"; }}"
        )
        tree_files.setdefault(owner, []).append(rel)
        return fid

    def group(rel_dir: str, owner: str, name: str | None = None) -> str:
        gid = oid("group", rel_dir)
        dirs, files = walk(rel_dir)
        children = [group(f"{rel_dir}/{d}", owner) for d in dirs]
        children += [file_ref(f"{rel_dir}/{f}", owner) for f in files]
        label = f"name = {q(name)}; " if name else ""
        objs[gid] = (
            "{isa = PBXGroup; children = (" + "".join(f"{c}, " for c in children) + "); "
            f"{label}path = {q(Path(rel_dir).name)}; sourceTree = \"<group>\"; }}"
        )
        return gid

    app_groups = [group(app_dir, app_dir) for _, app_dir, _ in TARGETS]
    apps_group = oid("group", "Apps")
    objs[apps_group] = (
        "{isa = PBXGroup; children = (" + "".join(f"{g}, " for g in app_groups) + "); "
        "path = Apps; sourceTree = \"<group>\"; }"
    )
    pkg_group = group(PACKAGE_PATH, PACKAGE_PATH)
    packages_group = oid("group", "Packages")
    objs[packages_group] = "{isa = PBXGroup; children = (" + pkg_group + ", ); path = Packages; sourceTree = \"<group>\"; }"
    config_group = group("Config", "Config")

    products = {t: oid("product", t) for t, _, _ in TARGETS}
    for t, pid in products.items():
        objs[pid] = (
            "{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; "
            f"path = {t}.app; sourceTree = BUILT_PRODUCTS_DIR; }}"
        )
    products_group = oid("group", "Products")
    objs[products_group] = (
        "{isa = PBXGroup; children = (" + "".join(f"{p}, " for p in products.values())
        + "); name = Products; sourceTree = \"<group>\"; }"
    )
    main_group = oid("group", "<main>")
    objs[main_group] = (
        f"{{isa = PBXGroup; children = ({apps_group}, {packages_group}, {config_group}, {products_group}, ); "
        "sourceTree = \"<group>\"; }"
    )

    pkg_ref = oid("pkgref", PACKAGE_PATH)
    objs[pkg_ref] = f"{{isa = XCLocalSwiftPackageReference; relativePath = {q(PACKAGE_PATH)}; }}"

    def config_list(scope: str, base_for) -> str:
        ids = []
        for name in ("Debug", "Release"):
            cid = oid("config", scope, name)
            base = oid("file", base_for(name))
            objs[cid] = (
                f"{{isa = XCBuildConfiguration; baseConfigurationReference = {base}; "
                f"buildSettings = {{ }}; name = {name}; }}"
            )
            ids.append(cid)
        lid = oid("configlist", scope)
        objs[lid] = (
            "{isa = XCConfigurationList; buildConfigurations = ("
            + "".join(f"{i}, " for i in ids)
            + "); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }"
        )
        return lid

    target_ids = []
    for t, app_dir, xcconfig in TARGETS:
        sources, resources = [], []
        for rel in tree_files.get(app_dir, []):
            ext = Path(rel).suffix
            if ext in SOURCE_EXT:
                bid = oid("build", t, rel)
                objs[bid] = f"{{isa = PBXBuildFile; fileRef = {oid('file', rel)}; }}"
                sources.append(bid)
            elif ext in RESOURCE_EXT:
                bid = oid("build", t, rel)
                objs[bid] = f"{{isa = PBXBuildFile; fileRef = {oid('file', rel)}; }}"
                resources.append(bid)
        pkg_dep = oid("pkgdep", t, PACKAGE_PRODUCT)
        objs[pkg_dep] = (
            f"{{isa = XCSwiftPackageProductDependency; package = {pkg_ref}; productName = {PACKAGE_PRODUCT}; }}"
        )
        pkg_build = oid("build", t, "pkg", PACKAGE_PRODUCT)
        objs[pkg_build] = f"{{isa = PBXBuildFile; productRef = {pkg_dep}; }}"
        ph_src, ph_fw, ph_res = oid("phase", t, "src"), oid("phase", t, "fw"), oid("phase", t, "res")
        objs[ph_src] = (
            "{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ("
            + "".join(f"{b}, " for b in sources) + "); runOnlyForDeploymentPostprocessing = 0; }"
        )
        objs[ph_fw] = (
            f"{{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({pkg_build}, ); "
            "runOnlyForDeploymentPostprocessing = 0; }"
        )
        objs[ph_res] = (
            "{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ("
            + "".join(f"{b}, " for b in resources) + "); runOnlyForDeploymentPostprocessing = 0; }"
        )
        tid = oid("target", t)
        objs[tid] = (
            f"{{isa = PBXNativeTarget; buildConfigurationList = {config_list(t, lambda _n, x=xcconfig: x)}; "
            f"buildPhases = ({ph_src}, {ph_fw}, {ph_res}, ); buildRules = ( ); dependencies = ( ); "
            f"name = {t}; packageProductDependencies = ({pkg_dep}, ); productName = {t}; "
            f"productReference = {products[t]}; productType = \"com.apple.product-type.application\"; }}"
        )
        target_ids.append(tid)

    project = oid("project")
    objs[project] = (
        "{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = 1; "
        "LastSwiftUpdateCheck = 1520; LastUpgradeCheck = 1520; }; "
        f"buildConfigurationList = {config_list('project', lambda n: f'Config/{n}.xcconfig')}; "
        "compatibilityVersion = \"Xcode 14.0\"; "
        "developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base, \"pt-BR\", ); "
        f"mainGroup = {main_group}; packageReferences = ({pkg_ref}, ); productRefGroup = {products_group}; "
        "projectDirPath = \"\"; projectRoot = \"\"; targets = ("
        + "".join(f"{t}, " for t in target_ids) + "); }"
    )

    body = "".join(f"\t\t{k} = {v};\n" for k, v in sorted(objs.items()))
    pbxproj = (
        "// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 60;\n"
        "\tobjects = {\n" + body + "\t};\n" f"\trootObject = {project};\n}}\n"
    )
    out = {"project.pbxproj": pbxproj, "project.xcworkspace/contents.xcworkspacedata": WORKSPACE}
    for (t, _, _), tid in zip(TARGETS, target_ids):
        out[f"xcshareddata/xcschemes/{t}.xcscheme"] = scheme(t, tid)
    return out


WORKSPACE = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
"""


def scheme(name: str, target: str) -> str:
    ref = (
        f'BuildableIdentifier = "primary" BlueprintIdentifier = "{target}" '
        f'BuildableName = "{name}.app" BlueprintName = "{name}" '
        f'ReferencedContainer = "container:{PROJ.name}"'
    )
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1520" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference {ref}>
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference {ref}>
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""


def main() -> int:
    files = generate()
    if "--check" in sys.argv:
        stale = [n for n, c in files.items() if not (PROJ / n).is_file() or (PROJ / n).read_text(encoding="ascii") != c]
        for n in stale:
            print(f"DESATUALIZADO: {PROJ.name}/{n}")
        print("PROJECT_OK" if not stale else "PROJECT_STALE (rode: python3 tools/gen_project.py)")
        return 0 if not stale else 1
    for name, content in files.items():
        path = PROJ / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="ascii")
        print(f"gravado {PROJ.name}/{name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
