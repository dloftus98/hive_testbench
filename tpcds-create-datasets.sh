#!/bin/bash

function usage {
        echo "Usage: tpcds-create-datasets.sh dataset_name_prefix num_datasets format scale_factor"
        exit 1
}

DATASET_NAME_PREFIX=$1
NUM_DATASETS=$2
FORMAT=$3
SCALE=$4

if [ X"$DATASET_NAME_PREFIX" = "X" ]; then
        usage
fi

if [ X"$NUM_DATASETS" = "X" ]; then
        usage
fi

if [ X"$FORMAT" = "X" ]; then
        usage
fi

if [ X"$SCALE" = "X" ]; then
        usage
fi

for i in $(eval echo "{1..$NUM_DATASETS}");
do
   ./tpcds-setup.sh ${DATASET_NAME_PREFIX}${i} $FORMAT $SCALE
done    

