#!/bin/bash
# This line tells the system to run the script with the bash shell.

#SBATCH -J basecall_demux
# Sets the job name in SLURM to "basecall_demux". Useful for monitoring jobs.

#SBATCH -o slurm_logs/basecall_demux_%j.out
# Redirects standard output (stdout) to a file in the "slurm_logs" directory.
# %j will be replaced with the job ID so each run gets a unique log file.

#SBATCH -e slurm_logs/basecall_demux_%j.err
# Redirects standard error (stderr) to a separate log file in the "slurm_logs" directory.
# Again, %j ensures uniqueness per job.

#SBATCH -p gpu
# Requests the "gpu" partition/queue. This ensures the job runs on GPU-capable nodes.

#SBATCH --gpus 2
# Requests 2 GPUs for this job (dorado basecalling is GPU-intensive).

#SBATCH -t 24:00:00
# Sets a time limit of 24 hours for the job. The scheduler will kill the job if it exceeds this.

#SBATCH -c 16
# Requests 16 CPU cores in addition to the GPUs. Dorado benefits from CPUs for preprocessing/postprocessing.

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

# Run the orchestrator script that handles basecalling and demultiplexing.
bash job/basecall_demux.sh