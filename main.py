"""
Model aggregation strategies.

FedAvg  — uniform average of all weight dicts.
Weighted FedAvg — average weighted by the number of training samples each
                  node used, which is closer to what McMahan et al. describe.
"""
import logging
from typing import Dict, List, Any, Optional

import torch

logger = logging.getLogger(__name__)

WeightDict = Dict[str, Any]   # str -> nested list of floats


def federated_average(
    local_weights: WeightDict,
    peer_weights_list: List[WeightDict],
) -> WeightDict:
    """
    Simple unweighted FedAvg.

    Args:
        local_weights:    current node's weight dict
        peer_weights_list: list of weight dicts received from gossip peers

    Returns:
        A new weight dict that is the element-wise mean of all inputs.
    """
    if not peer_weights_list:
        return local_weights

    all_weights = [local_weights] + peer_weights_list
    n = len(all_weights)
    averaged: WeightDict = {}

    for key in local_weights:
        tensors = [torch.tensor(w[key], dtype=torch.float32) for w in all_weights]
        averaged[key] = (sum(tensors) / n).tolist()

    logger.debug("FedAvg: averaged %d models", n)
    return averaged


def weighted_federated_average(
    local_weights: WeightDict,
    local_samples: int,
    peer_weights_list: List[WeightDict],
    peer_samples: List[int],
) -> WeightDict:
    """
    Weighted FedAvg — each model's contribution is proportional to the
    number of training examples it was trained on.
    """
    all_weights = [local_weights] + peer_weights_list
    all_samples = [local_samples] + peer_samples
    total = sum(all_samples)

    if total == 0:
        return local_weights

    averaged: WeightDict = {}
    for key in local_weights:
        tensors = [torch.tensor(w[key], dtype=torch.float32) for w in all_weights]
        weighted_sum = sum(t * (s / total) for t, s in zip(tensors, all_samples))
        averaged[key] = weighted_sum.tolist()

    logger.debug("Weighted FedAvg: total samples=%d", total)
    return averaged
