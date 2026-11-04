# Third-party assets and licensing — November 4, 2026

This is a **provenance/redistribution audit**, not a license assignment or publication authorization.

## Herb artwork — 29 exact matches

All **29** `Icons/Herb*.tga` files in GatherMap's `feat/forever-port` tree were compared against the files at the **same paths** in [jsb/Gatherer](https://github.com/jsb/Gatherer/tree/master/Icons). **29/29 Git blob SHA values matched exactly**, demonstrating byte-identical content in that historical upstream repository; there were no differing or missing icon files.

The [Gatherer CurseForge project](https://www.curseforge.com/wow/addons/gatherer/license) and [Gatherer SourceForge listing](https://sourceforge.net/projects/gatherer/) identify **GPL version 2** for their distributions. The historical `jsb/Gatherer` fork contains [a README](https://github.com/jsb/Gatherer/blob/master/Readme.txt) that credits an older 1.12 Gatherer version; it does not carry a root `LICENSE` file. Its source contains additional credits, including original author Chandora and MapNotes-derived material. These findings strongly support Gatherer provenance, but do **not** establish independently whether every artwork file was authored by its credited contributor and placed under the same GPL terms. Preserve all original notices and obtain a clear license chain before publishing a new Forever package.

## Historical map information

- Gatherer map scaling and normalization were previously credited to Gatherer/MapNotes, as recorded in `docs/CONTENT.md`. The modern Forever runtime uses `C_Map` rather than distributing these old scaling tables as active code.
- Grim Reaches dimensions were credited to [MetaHunt](https://octowow.st/git/Meta/MetaHunt), a mirror pointing to [Duvelcorp/MetaHunt on Codeberg](https://codeberg.org/Duvelcorp/MetaHunt). We did not establish the precise original source file, copyright grant, or whether these dimensions are still used by the new Forever runtime. The historical attribution stays intact.
- Existing screenshots are documentation, not required addon runtime assets. Their original authorship and publication permissions remain subject to normal project review.

## Pending decisions and release boundary

- **Do not assign a repository-wide license without Babuni's authorization.** This repository currently has no root `LICENSE`. Public visibility alone does not grant redistribution rights.
- Determine whether the 29 historical icons can be distributed under the complete original Gatherer license/notice conditions or must be replaced with permitted assets. No art removal or substitution has been authorized.
- Preserve Gatherer, MapNotes, Norganna and MetaHunt credits as applicable; distinguish Babuni's creative direction and the modern AI-assisted port.
- Resolve any third-party notices required inside a **public Forever package** before tagging, publishing or uploading to CurseForge. The developer ZIP checker is not a publication approval.
