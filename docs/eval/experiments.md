## E1 - hits (of 11) vs confidence threshold
| tau | 0.25 | 0.4 | 0.5 | 0.6 | 0.7 | 0.8 | 0.9 |
|---|---|---|---|---|---|---|---|
| resize | 11 | 11 | 11 | 9 | 9 | 8 | 3 |
| letterbox | 11 | 11 | 11 | 11 | 11 | 10 | 5 |

## E2 - perturbations (letterbox, tau 0.25)
| perturbation | hits/11 | mean conf | wrong-class boxes |
|---|---|---|---|
| original | 11 | 0.866 | 0 |
| dark x0.4 | 11 | 0.867 | 0 |
| bright x1.8 | 10 | 0.771 | 0 |
| blur r=3 | 11 | 0.848 | 1 |
| blur r=8 | 8 | 0.591 | 1 |
| JPEG q=20 | 11 | 0.874 | 0 |
| noise sigma=0.08 | 11 | 0.88 | 1 |
| rotate +15 deg | 11 | 0.866 | 0 |
| rotate -15 deg | 11 | 0.851 | 0 |
| occlusion 25% | 5 | 0.305 | 1 |
| downscale x0.25 | 11 | 0.87 | 0 |

## E3 - negatives (15 images)
| tau | images with a detection | boxes |
|---|---|---|
| 0.25 | 2 | 2 |
| 0.5 | 1 | 1 |
| 0.7 | 1 | 1 |

## E4 - latency vs threads
| threads | mean ms | p95 ms |
|---|---|---|
| 1 | 242.6 | 247.3 |
| 2 | 137.5 | 141.0 |
| 4 | 87.0 | 89.0 |
| 8 | 70.2 | 72.6 |
