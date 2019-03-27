#!/bin/bash
#SBATCH --job-name=matlabHTM55
#SBATCH --time=08:00:00
#SBATCH --output=Output/malabHTM55.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2018b

matlab -nodisplay -nosplash -r "run('runNAB(55,56,false,true)')"


