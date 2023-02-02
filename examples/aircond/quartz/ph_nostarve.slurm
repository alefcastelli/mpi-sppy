#!/bin/bash -l
#SBATCH --job-name=aircond_demo_slurm
#SBATCH --output=try_big_pickles_ph_nostarve.out
#SBATCH --ntasks=1800
#SBATCH --nodes=201
#SBATCH --time=00:60:00
#SBATCH --account=mpisppy
#SBATCH --mail-type=ALL

export MPICH_ASYNC_PROGRESS=1
source ${HOME}/venvs/mpisppy-jan2022/bin/activate

date
NODENAME="$(srun hostname)"
echo ${NODENAME[0]}

SOLVERNAME="gurobi_persistent"

REPLICANT=1
PICKLE_DIR="/p/lustre1/watson61/aircond/$REPLICANT"

BF1=1000
BF2=25
BF3=10
BF4=4
let SPB=BF2*BF3*BF4
let SC=BF1*BF2*BF3*BF4
let PBF=BF1  # by design, this is the number of bundles

BI=50
NC=1
QSC=0.3
SD=40
OTC=5

let SEED=(REPLICANT-1)*1000000

EC="--Capacity 200 --QuadShortCoeff $QSC  --BeginInventory $BI --mu-dev 0 --sigma-dev $SD --start-seed $SEED --NegInventoryCost=$NC --OvertimeProdCost=$OTC"
# --start-ups

# There are no restrictions on the number of processors for the pickler and it could be given as many as the maxiumum number of cores (or threads?) that will be used in the next step.
# we are relying on APH script to generate the instances
#echo "^^^^^^^^^ Make pickle bundles"
srun -n $SLURM_NTASKS unbuffer python -m mpi4py bundle_pickler.py --branching-factors $BF1 $BF2 $BF3 $BF4 --pickle-bundles-dir=$PICKLE_DIR --scenarios-per-bundle=$SPB $EC

#echo "***** Use pickle bundles"
# It is entirely up to the user to make sure that the scenario count and scenarios per bundle match between creating the pickles and using them (the costs probably don't matter, since the pickle has it all)
srun -n $SLURM_NTASKS unbuffer python -m mpi4py aircond_cylinders.py --max-iterations=100 --default-rho=1 --solver-name=${SOLVERNAME} --branching-factors $PBF --rel-gap 0.0001 --abs-gap 2 --max-solver-threads 2 --start-seed $SEED --no-fwph --no-lagranger --bundles-per-rank=0  --scenarios-per-bundle=$SPB --intra-hub-conv-thresh 0 --unpickle-bundles-dir=$PICKLE_DIR $EC --with-display-progress --solver-options="method=0"
#--with-display-convergence-detail

###python aircond_cylinders.py --help

