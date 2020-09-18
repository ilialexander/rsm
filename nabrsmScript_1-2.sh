#!/bin/bash
#SBATCH --job-name=runNABRM_1-2
#SBATCH --time=00:20:00
#SBATCH --output=Output/matlabSRM.%j
#SBATCH --ntasks=1
#SBATCH --mem=8192

module load apps/matlab/r2018b

date

matlab -nodisplay -nosplash -r "run('runNAB(1,2,false,true,true,false)')"

date


