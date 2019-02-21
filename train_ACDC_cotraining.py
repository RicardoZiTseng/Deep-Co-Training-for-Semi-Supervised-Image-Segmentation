import os
import random
import warnings
from pprint import pprint

import numpy as np
import torch
import yaml

from generalframework.dataset import get_ACDC_dataloaders, extract_patients
from generalframework.loss import get_loss_fn
from generalframework.models import Segmentator
from generalframework.trainer import CoTrainer
from generalframework.utils import yaml_parser, dict_merge

warnings.filterwarnings('ignore')


def fix_seed(seed):
    random.seed(seed)
    torch.manual_seed(seed)
    torch.cuda.manual_seed_all(seed)
    np.random.seed(seed)
    os.environ['PYTHONHASHSEED'] = str(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False


fix_seed(1234)
parser_args = yaml_parser()
print('->>Input args:')
pprint(parser_args)
with open('config/ACDC_config_cotrain.yaml', 'r') as f:
    config = yaml.load(f.read())
print('->> Merged Config:')
config = dict_merge(config, parser_args, True)
pprint(config)


def get_models(config):
    num_models = config['Lab_Partitions']['label'].__len__()
    for i in range(num_models):
        return [Segmentator(arch_dict=config['Arch'], optim_dict=config['Optim'], scheduler_dict=config['Scheduler'])
                for _ in range(num_models)]


def get_dataloders(config):
    dataloders = get_ACDC_dataloaders(config['Dataset'], config['Lab_Dataloader'])

    partition_ratio = config['Lab_Partitions']['partition_sets']
    lab_ids, unlab_ids = create_partitions(partition_ratio)
    # print(list(lab_ids))
    # print(list(unlab_ids))

    partition_divers = config['Lab_Partitions']['partition_diversity']
    rd_idx = np.random.permutation(range(*lab_ids))
    overlap_idx = np.random.choice(rd_idx, size=int(partition_divers / 100 * range(*lab_ids).__len__()),
                                   replace=False)
    exclusive_idx = [x for x in rd_idx if x not in overlap_idx]

    n_splits = 2
    overlap_samples = int(overlap_idx.size / n_splits)
    over_indx = [overlap_idx[i * overlap_samples: (i+1) * overlap_samples] for i in range(n_splits)]

    exclusive_samples = int(exclusive_idx.__len__() / n_splits)
    excl_indx = [exclusive_idx[i * exclusive_samples: (i + 1) * exclusive_samples] for i in range(n_splits)]

    lab_partitions = [np.hstack((over_indx[idx], np.array(excl_indx[idx]))) for idx in range(n_splits)]
    labeled_dataloaders = []
    for idx_lst in lab_partitions:
        labeled_dataloaders.append(extract_patients(dataloders['train'], [str(x) for x in idx_lst]))

    unlab_dataloader = get_ACDC_dataloaders(config['Dataset'], config['Unlab_Dataloader'], quite=True)['train']
    unlab_dataloader = extract_patients(unlab_dataloader, [str(x) for x in range(*unlab_ids)])
    val_dataloader = dataloders['val']
    return labeled_dataloaders, unlab_dataloader, val_dataloader


def create_partitions(partition_ratio=60):
    lab_ids = [1, partition_ratio+1]
    unlab_ids = [partition_ratio+1, 101]
    # print('Labeled and unlabeled partition is: {}'.format(partition_ratio))
    return lab_ids, unlab_ids


labeled_dataloaders, unlab_dataloader, val_dataloader = get_dataloders(config)

segmentators = get_models(config)

with warnings.catch_warnings():
    warnings.filterwarnings("ignore", category=UserWarning)
    criterions = {'sup': get_loss_fn('cross_entropy'),
                  'jsd': get_loss_fn('jsd'),
                  'adv': get_loss_fn('jsd')}

cotrainner = CoTrainer(segmentators=segmentators,
                       labeled_dataloaders=labeled_dataloaders,
                       unlabeled_dataloader=unlab_dataloader,
                       val_dataloader=val_dataloader,
                       criterions=criterions,
                       adv_scheduler_dict=config['Adv_Scheduler'],
                       cot_scheduler_dict=config['Cot_Scheduler'],
                       adv_training_dict=config['Adv_Training'],
                       **config['Trainer'],
                       whole_config=config)

cotrainner.start_training(**config['StartTraining'])
