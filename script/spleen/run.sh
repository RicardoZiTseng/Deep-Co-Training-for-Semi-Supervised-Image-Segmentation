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

account=def-mpederso  #rrg-mpederso, def-mpederso, and def-chdesa
time=12
main_dir="spleen"
max_epoch=1
seed=1
load_checkpoint="#"


declare -a StringArray=(
"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=${main_dir}/${seed}/baseline  \
Trainer.max_epoch=${max_epoch} Seed=${seed} \
${load_checkpoint}Trainer.checkpoint_path=runs/${main_dir}/${seed}/baseline " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=${main_dir}/${seed}/jsd  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_jsd=True \
${load_checkpoint}Trainer.checkpoint_path=runs/${main_dir}/${seed}/jsd " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=${main_dir}/${seed}/adv  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_adv=True \
${load_checkpoint}Trainer.checkpoint_path=runs/${main_dir}/${seed}/adv " \

"python -O train_ACDC_cotraining.py Config=config/spleen_config_cotraing.yaml Trainer.save_dir=${main_dir}/${seed}/jsd_adv  \
Trainer.max_epoch=${max_epoch} Seed=${seed} StartTraining.train_jsd=True StartTraining.train_adv=True \
${load_checkpoint}Trainer.checkpoint_path=runs/${main_dir}/${seed}/jsd_adv " \
)
#
for cmd in "${StringArray[@]}"
do
echo ${cmd}
#wrapper "${time}" "${account}" "${cmd}"
 ${cmd}
done