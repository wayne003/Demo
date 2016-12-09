#!/bin/bash
#SBATCH --job-name=TestRun
#SBATCH --partition=commons
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=03:00:00
#SBATCH --mem-per-cpu=6G
#SBATCH --output=job.out
echo "My job ran on:"
echo $SLURM_NODELIST
# srun is Davinci command which will run the commands which follow on a compute node
srun R CMD BATCH --no-save ~/stat640/finalproject/main.R
