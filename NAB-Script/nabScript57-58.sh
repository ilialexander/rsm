#!/bin/bash
#SBATCH --job-name=matlabHTM57
#SBATCH --time=12:00:00
#SBATCH --output=Output/malabHTM57.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2018b

matlab -nodisplay -nosplash -r "run('runNAB(57,58,false,true)')"


