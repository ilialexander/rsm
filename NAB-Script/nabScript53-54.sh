#!/bin/bash
#SBATCH --job-name=matlabHTM53
#SBATCH --time=08:00:00
#SBATCH --output=Output/malabHTM53.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2018b

matlab -nodisplay -nosplash -r "run('runNAB(53,54,false,true)')"


