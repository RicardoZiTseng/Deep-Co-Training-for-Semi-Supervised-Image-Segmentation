#!/usr/bin/env bash
CURRENT_PATH=$(pwd)
PROJECT_PATH="$(dirname "${CURRENT_PATH}")"
PROJECT_PATH="$(dirname "${PROJECT_PATH}")"
WRAPPER_PATH="CC_wrapper.sh"
echo "The project path: ${PROJECT_PATH}"
echo "The current path: ${CURRENT_PATH}"
echo "The wrapper path: ${WRAPPER_PATH}"
source $WRAPPER_PATH
cd ${PROJECT_PATH}
set -e

account=$3  #rrg-mpederso, def-mpederso, and def-chdesa
time=24
max_epoch=1
seed=1
load_checkpoint="#"
partition_ratio=$1
resolution=$2
main_dir="1015/spleen_re_${resolution}"


declare -a StringArray=(
"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=runs/${main_dir}/${seed}/baseline  \
Trainer.max_epoch=${max_epoch} Seed=${seed} Lab_Partitions.partition_sets=${partition_ratio} \
Dataset.transform=\"segment_transform((${resolution},${resolution}))\" \
${load_checkpoint}Trainer.checkpoint=runs/${main_dir}/${seed}/baseline " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=runs/${main_dir}/${seed}/jsd  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_jsd=True  Lab_Partitions.partition_sets=${partition_ratio} \
Dataset.transform=\"segment_transform((${resolution},${resolution}))\" \
${load_checkpoint}Trainer.checkpoint=runs/${main_dir}/${seed}/jsd " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=runs/${main_dir}/${seed}/adv  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_adv=True  Lab_Partitions.partition_sets=${partition_ratio} \
Dataset.transform=\"segment_transform((${resolution},${resolution}))\" \
${load_checkpoint}Trainer.checkpoint=runs/${main_dir}/${seed}/adv " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=runs/${main_dir}/${seed}/jsd_adv  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_jsd=True StartTraining.train_adv=True Lab_Partitions.partition_sets=${partition_ratio} \
Dataset.transform=\"segment_transform((${resolution},${resolution}))\" \
${load_checkpoint}Trainer.checkpoint=runs/${main_dir}/${seed}/jsd_adv " \
)
#
for cmd in "${StringArray[@]}"
do
echo ${cmd}
wrapper "${time}" "${account}" "${cmd}" 16
# ${cmd}
done
