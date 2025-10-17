#!/bin/bash
# This line tells the system to run the script with the Bash shell.

#SBATCH -J basecall_demux
# Sets the job name in SLURM to "basecall_demux". Useful for monitoring jobs.

#SBATCH -o logs/basecall_demux_%j.out
# Redirects standard output (stdout) to a file in the "logs" directory.
# %j will be replaced with the job ID so each run gets a unique log file.

#SBATCH -e logs/basecall_demux_%j.err
# Redirects standard error (stderr) to a separate log file in the "logs" directory.
# Again, %j ensures uniqueness per job.

#SBATCH -p gpu
# Requests the "gpu" partition/queue. This ensures the job runs on GPU-capable nodes.

#SBATCH --gpus 2
# Requests 2 GPUs for this job (Dorado basecalling is GPU-intensive).

#SBATCH -t 24:00:00
# Sets a time limit of 24 hours for the job. The scheduler will kill the job if it exceeds this.

#SBATCH -c 16
# Requests 16 CPU cores in addition to the GPUs. Dorado benefits from CPUs for preprocessing/postprocessing.

# ------------------ Runtime environment setup ------------------

# Load your environment configuration from .bashrc
# (This makes sure conda and other tools are available.)
source ~/.bashrc

# Activate the "test" conda environment (which presumably contains Dorado and dependencies).
conda activate nanopore_env

# Move to the working directory for the project.
cd ~/nanopore/

# ------------------ Main job execution ------------------

# Run the orchestrator script that handles basecalling and demultiplexing.
bash job/basecall_demux.sh