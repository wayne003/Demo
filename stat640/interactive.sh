source module_load.sh
srun --pty --partition=interactive --ntasks=1 --mem-per-cpu=6G --cpus-per-task=2 --time=00:10:00 $SHELL

