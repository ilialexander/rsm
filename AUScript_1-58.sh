#!/bin/bash
#SBATCH --job-name=AUSIndices_1-58
#SBATCH --time=4:00:00
#SBATCH --output=Output/AUIndices.%j
#SBATCH --ntasks=8
#SBATCH --mem=16384

module load apps/matlab/r2018b

date

matlab -nodisplay -nosplash -r "run('automatizationUnit(1,58)')"

date


