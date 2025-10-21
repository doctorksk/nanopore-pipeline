#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
# ##############################################################
# Configuration file for Nanopore basecalling and analysis
# ##############################################################
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'

########################
# DORADO MODEL SELECTION
########################

# Indicate dorado version, e.g. dorado-0.6.0-linux-x64
dorado_dir=dorado-1.1.1-linux-x64
# Indicate basecalling model, e.g. model/dna_r10.4.1_e8.2_400bps_sup@v5.2.0
model_dir=dna_r10.4.1_e8.2_400bps_sup@v5.2.0

#########################
# EXPERIMENTAL PARAMETERS
#########################

# Indicate name of edited input sheet, e.g. input_sheet_edit.csv
sheet_dir=input_sheet_edit.csv

######################
# TRIMMING AND MAPPING
######################

# Change to false if no trimming is needed
map=TRUE

# Indicate minimum read quality
quality=10

# Indicate minimum read length to keep, default 1
minlength=1500

# Indicate maximum read length to keep, default 2147483647
maxlength=6000

#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
# ##############################################################
# Pipeline by Gabriel Martínez-Gálvez
# v9
# ##############################################################
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'