#!/bin/bash
#SBATCH --job-name=matlabHTM
#SBATCH --time=20:00:00
#SBATCH --output=Output/malabHTM.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2018b

matlab -nodisplay -nosplash -r "run('runNAB(49,50,false,true)')"


