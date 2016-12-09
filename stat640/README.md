## STAT640 Final Projects


[Project Log](/ProjectNote.md)

[Final Report](/Report.pdf)

The structure of the project are:

### Directory

(/subdata) Contain subsetted data, which have 500 rows of training datasets. This is used for explorotory and prototyping.

(/FinalReport) Contain file needed to compile report.

(/sound) Matlab code for reconstructing sound

---

### Files

(/main.R) is the main job file. Batch this file to Research Computer

(/SliceData.R) objected to slice data to produce content under `\subdata`. It only needed to be ran once.

(/library.R) contain all the library required, non standard packages should be installed under login node on Research Computer

(/p1_function.R) contain some basic method fitting and predicting model, only for testing use

(/function.R) contain all the functions needed.

(/submit.slurm) SBATCH script for submitting job etc.

(/module_load.sh) command to load module on Research computer, use under shell `source ./module_load.sh`

(/interactive.sh) command to enter interactive node
