#!/bin/bash
# This script is run with the Bash shell.

#SBATCH -J trim_map
# Sets the SLURM job name to "trim_map".
# Makes it easier to track the job in the queue.

#SBATCH -o logs/trim_map_%j.out
# Redirects standard output (stdout) to a log file in the "logs" directory.
# %j gets replaced by the SLURM job ID to keep log files unique.

#SBATCH -e logs/trim_map_%j.err
# Redirects standard error (stderr) to a separate log file in the "logs" directory.
# Again, %j ensures uniqueness per job run.

#SBATCH -p cpu
# Submits the job to the "cpu" partition (queue).
# Unlike Dorado, this stage only requires CPUs.

#SBATCH -t 12:00:00
# Sets a maximum runtime of 12 hours.
# The scheduler will terminate the job if it runs longer.

#SBATCH -c 8
# Requests 8 CPU cores for this job.
# Trimming and mapping are multithreaded, so this speeds up execution.

# ------------------ Runtime environment setup ------------------

# Load user shell configuration to make sure conda and other tools are available.
source ~/.bashrc

# Activate the "test" conda environment (which should contain cutadapt, minimap2, samtools, etc.).
conda activate nanopore_env

# Move into the working project directory.
cd ~/nanopore/

# ------------------ Main job execution ------------------

# Run the orchestrator script that performs read trimming and mapping.
bash job/trim_map.sh