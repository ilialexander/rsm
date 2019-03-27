#!/bin/bash
#SBATCH --job-name=matlabHTM
#SBATCH --time=30:00:00
#SBATCH --output=Output/malabHTM.%j
#SBATCH --ntasks=4
#SBATCH --mem=16384

module load apps/matlab/r2018b

nice -n 10 matlab -nodisplay -nosplash -nodesktop -r "run('runNAB(50,52,true,true)')" &
nice -n 10 matlab -nodisplay -nosplash -nodesktop -r "run('runNAB(53,54,true,true)')" &
nice -n 10 matlab -nodisplay -nosplash -nodesktop -r "run('runNAB(55,56,true,true)')" &
nice -n 10 matlab -nodisplay -nosplash -nodesktop -r "run('runNAB(57,58,true,true)')" & 


