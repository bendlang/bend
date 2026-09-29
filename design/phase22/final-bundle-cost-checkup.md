# Final bundle host descriptor update: checkup file-open behavior

Preserve bundle-matrix-inputs-01 and its consumed preparer. Source10/context-build-09 keeps the exact compiled API of context-build-08 and adds only the independently reviewed per-import `--checkup` file-open/catch behavior to tools/typed-driver.mjs. The command now opens a matched import before inspection and prints the original file-open exception, records a failing exit and continues to later imports, matching the pinned command.

Create a fresh explicit host review and preparer version, then bundle-matrix-inputs-02. The sole changed host path remains tools/typed-driver.mjs; all other34 host files, Base, runtime, pin, frozen Phase21 workload and resources stay identical. The candidate host identity now includes both ABI2 retirement and this precise checkup correction. Keep full result equality and the sole verified hostProvenance exclusion unchanged. No performance claim or timing authorization follows from preparing these inputs.

The earlier host mocks contain only existing top-level checkup files and a semantic child rejection; their existing scope and expectations are unaffected. They did not claim missing-top-level-file coverage. Root's actual four checkup CLI controls exercise the new behavior directly, so no mock oracle or prior result needs revision.
