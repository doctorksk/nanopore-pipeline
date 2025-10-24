#!/bin/bash
# This script is run with the bash shell.

#SBATCH -J trim_map
# Sets the SLURM job name to "trim_map".
# Makes it easier to track the job in the queue.

#SBATCH -o slurm_logs/trim_map_%j.out
# Redirects standard output (stdout) to a log file in the "slurm_logs" directory.
# %j gets replaced by the SLURM job ID to keep log files unique.

#SBATCH -e slurm_logs/trim_map_%j.err
# Redirects standard error (stderr) to a separate log file in the "slurm_logs" directory.
# Again, %j ensures uniqueness per job run.

#SBATCH -p cpu
# Submits the job to the "cpu" partition (queue).

#SBATCH -t 12:00:00
# Sets a maximum runtime of 12 hours.
# The scheduler will terminate the job if it runs longer.

#SBATCH -c 8
# Requests 8 CPU cores for this job.
# Trimming and mapping are multithreaded, so this speeds up execution.

# ------------------ Runtime environment setup ------------------

# Load and activate miniconda3 module (This makes sure conda and other tools are available).
module load miniconda3
eval "$(conda shell.bash hook)"

# Activate the "nanopore_env" conda environment
conda activate nanopore_env

# ------------------ Repository path handling ------------------

# Automatically find the directory of this SLURM script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Move to the directory from which sbatch was run, i.e. nanopore_pipeline
cd "$SLURM_SUBMIT_DIR"

# Confirm current working directory (appears in SLURM .out log)
echo "Running from project root: $(pwd)"

# ------------------ Main job execution ------------------

# Run the orchestrator script that performs read trimming and mapping.
bash job/trim_map.sh