#!/bin/bash
#SBATCH --job-name=matlabHTM+PreAU_1-58
#SBATCH --time=24:00:00
#SBATCH --output=Output/matlabHTMPreAU.%j
#SBATCH --ntasks=8
#SBATCH --mem=16384

module load apps/matlab/r2018b

date

matlab -nodisplay -nosplash -r "run('runNABPreAU(1,58,false,true)')"

date


