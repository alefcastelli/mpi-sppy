#!/bin/bash -l
#SBATCH --job-name=aircond_demo_slurm
#SBATCH --output=big_test.out
#SBATCH --ntasks=45
#SBATCH --nodes=2
#SBATCH --time=00:05:00
#SBATCH --account=mpisppy
#SBATCH --mail-type=ALL

export MPICH_ASYNC_PROGRESS=1
source ${HOME}/venvs/mpisppy-jan2023/bin/activate

date
NODENAME="$(srun hostname)"
echo ${NODENAME[0]}

SOLVERNAME="gurobi_persistent"

PICKLE_DIR=/p/lustre1/watson61/aircond

BF1=45
BF2=50
BF3=20
let SPB=BF2*BF3
let SC=BF1*BF2*BF3
let PBF=BF1  # by design, this is the number of bundles

BI=50
NC=1
QSC=0.3
SD=40
OTC=5

SEED=0

EC="--Capacity 200 --QuadShortCoeff $QSC  --BeginInventory $BI --mu-dev 0 --sigma-dev $SD --start-seed 0 --NegInventoryCost=$NC --OvertimeProdCost=$OTC"
# --start-ups

# There are no restrictions on the number of processors for the pickler and it could be given as many as the maxiumum number of cores (or threads?) that will be used in the next step.
#echo "^^^^^^^^^ Make pickle bundles"
#srun -n $SLURM_NTASKS python -m mpi4py bundle_pickler.py --branching-factors "$BF1 $BF2 $BF3" --pickle-bundles-dir=$PICKLE_DIR --scenarios-per-bundle=$SPB $EC

srun -n $BF1 python -m mpi4py bundle_pickler.py --branching-factors "$BF1 $BF2 $BF3" --pickle-bundles-dir=$PICKLE_DIR --scenarios-per-bundle=$SPB $EC


#echo "***** Use pickle bundles"
# It is entirely up to the user to make sure that the scenario count and scenarios per bundle match between creating the pickles and using them (the costs probably don't matter, since the pickle has it all)
# BELOW IS FOR PH
#srun -n $SLURM_NTASKS unbuffer python -m mpi4py aircond_cylinders.py --max-iterations=100 --default-rho=1 --solver-name=${SOLVERNAME} --branching-factors $PBF --rel-gap 0.0001 --abs-gap 2 --max-solver-threads 2 --start-seed $SEED --bundles-per-rank=0  --scenarios-per-bundle=$SPB --write-solution --intra-hub-conv-thresh 0 --unpickle-bundles-dir=$PICKLE_DIR $EC --display-progress --solver-options="method=0" --lagrangian --xhatshuffle
#--with-display-convergence-detail

###python aircond_cylinders.py --help

# BELOW IS FOR APH

#srun -n $SLURM_NTASKS unbuffer python -m mpi4py aircond_cylinders.py --run-async --aph-frac-needed=1.0 --aph-dispatch-frac=0.20 --max-iterations=100 --default-rho=1 --solver-name=${SOLVERNAME} --branching-factors $PBF --rel-gap 0.0001 --abs-gap 2 --max-solver-threads 2 --start-seed $SEED --bundles-per-rank=0  --scenarios-per-bundle=$SPB --write-solution --intra-hub-conv-thresh 0 --unpickle-bundles-dir=$PICKLE_DIR $EC --display-progress --solver-options="method=0" --lagrangian --xhatshuffle

# BELOW IS FOR PH

# DON'T BREATHE ON THE BELOW...

srun -n $SLURM_NTASKS unbuffer python -m mpi4py aircond_cylinders.py --max-iterations=3 --default-rho=1 --solver-name=${SOLVERNAME} --branching-factors $PBF --rel-gap 0.0001 --abs-gap 2 --max-solver-threads 2 --start-seed $SEED --bundles-per-rank=0  --scenarios-per-bundle=$SPB --write-solution --intra-hub-conv-thresh 0 --unpickle-bundles-dir=$PICKLE_DIR $EC --display-progress --solver-options="method=0" --lagrangian --xhatshuffle

