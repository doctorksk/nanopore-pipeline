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

# Indicate path to dorado folder, e.g. dorado_model/dorado-0.6.0-linux-x64/bin/
dorado_dir=dorado_model/dorado-1.1.1-linux-x64/bin/

#########################
# EXPERIMENTAL PARAMETERS
#########################

# Indicate path to sample sheet, e.g. job/sample_sheet.csv
sheet_dir=job/EP151.csv

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