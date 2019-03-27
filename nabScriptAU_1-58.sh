#!/bin/bash
#SBATCH --job-name=matlabHTM+AU_1-58
#SBATCH --time=24:00:00
#SBATCH --output=Output/matlabHTMAU.%j
#SBATCH --ntasks=8
#SBATCH --mem=16384

module load apps/matlab/r2018b

date

matlab -nodisplay -nosplash -r "run('runNABAU(1,58,false,true)')"

date


