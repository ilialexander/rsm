#!/bin/bash
#SBATCH --partition=bgfsqdr
#SBATCH --job-name=rsm_1-58
#SBATCH --time=20:00:00
#SBATCH --output=Output/matlabRSM.%j
#SBATCH --ntasks=8
#SBATCH --mem=8192

module load apps/matlab/r2020b

date

matlab -nodisplay -nosplash -r "run('runNAB(1,58,false,true,true,false)')"

date


