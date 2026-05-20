# 搜索预算表（best 口径）

| Dataset | Method | Source | Result_type | numGridConfigs | numSeeds | numRuns | searchBudget | selectionRule | selectedConfig |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| Mfeat | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=100.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 10 | 480 | best_mean_ACC_then_NMI | beta=100.0000, lambda=1000.0000, lambdaBIC=0.0000, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A3_SSETarget | 本地消融结果 | best | 240 | 1 | 10 | 2400 | best_mean_ACC_then_NMI | beta=100.0000, lambda=1000.0000, lambdaBIC=0.5000, minNodeSize=32.0000, targetView=1.0000 |
| Mfeat | A4_woMultiViewFusion | 本地消融结果 | best | 80 | 1 | 10 | 800 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=1.5000, minNodeSize=24.0000, targetView=1.0000 |
| Reuters-1200 | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| Reuters-1200 | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 8 | Missing | 按重复评价均值+标准差上界 | beta=2000.0000, lambda=1000.0000, lambdaBIC=0.3500, minNodeSize=16.0000, targetView=1.0000 |
| Reuters-1200 | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=75.0000, lambda=100.0000, lambdaBIC=0.0000, minNodeSize=16.0000, targetView=3.0000 |
| Reuters-1200 | A3_SSETarget | 本地消融结果 | best | 192 | 1 | 8 | 1536 | best_mean_ACC_then_NMI | beta=50.0000, lambda=300.0000, lambdaBIC=0.5000, minNodeSize=10.0000, targetView=3.0000 |
| Reuters-1200 | A4_woMultiViewFusion | 本地消融结果 | best | 64 | 1 | 8 | 512 | best_mean_ACC_then_NMI | beta=50.0000, lambda=Missing, lambdaBIC=0.5000, minNodeSize=12.0000, targetView=4.0000 |
| WIKI | A0_Full_Reference | 本地 A0 结果（文本摘要） | best | Missing | 1 | 8 | Missing | best_mean_ACC_then_NMI | beta=120.0000, lambda=10000.0000, lambdaBIC=4.5000, minNodeSize=30.0000, targetView=2.0000 |
| WIKI | A1_woBIC_Joint | 本地消融结果 | best | 48 | 1 | 8 | 384 | best_mean_ACC_then_NMI | beta=80.0000, lambda=100.0000, lambdaBIC=0.0000, minNodeSize=50.0000, targetView=2.0000 |
| WIKI | A3_SSETarget | 本地消融结果 | best | 240 | 1 | 8 | 1920 | best_mean_ACC_then_NMI | beta=100.0000, lambda=300.0000, lambdaBIC=3.5000, minNodeSize=20.0000, targetView=2.0000 |
| WIKI | A4_woMultiViewFusion | 本地消融结果 | best | 80 | 1 | 8 | 640 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=3.5000, minNodeSize=50.0000, targetView=2.0000 |
| Caltech256 | Original 3AMVC Baseline | 本地原始 3AMVC 源码运行结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=30.0000, lambda=300000.0000, targetView=1.0000, anchors=53,70,45,79 |
| Caltech256 | A0_Full_Reference | 本地 A0 结果（日志解析） | best | Missing | 1 | 3 | Missing | best_mean_ACC_then_NMI | beta=200.0000, lambda=1000.0000, lambdaBIC=3.0000, minNodeSize=120.0000, targetView=3.0000 |
| Caltech256 | A1_woBIC_Joint | 本地消融结果 | best | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=500.0000, lambdaBIC=0.0000, minNodeSize=160.0000, targetView=3.0000 |
| Caltech256 | A3_SSETarget | 本地消融结果 | best | 48 | 1 | 3 | 144 | best_mean_ACC_then_NMI | beta=150.0000, lambda=10000.0000, lambdaBIC=3.0000, minNodeSize=80.0000, targetView=1.0000 |
| Caltech256 | A4_woMultiViewFusion | 本地消融结果 | best | 36 | 1 | 3 | 108 | best_mean_ACC_then_NMI | beta=200.0000, lambda=Missing, lambdaBIC=4.0000, minNodeSize=160.0000, targetView=3.0000 |
| ForestTypes | Original 3AMVC Baseline | 论文报告结果 | best | Missing | Missing | Missing | Missing | paper/local baseline; not directly comparable search budget | beta=Missing, lambda=Missing, targetView=Missing, anchors= |
| ForestTypes | A0_Full_Reference | 本地 A0 结果 | best | Missing | 1 | 10 | Missing | 按重复评价均值+标准差上界 | beta=200.0000, lambda=1000.0000, lambdaBIC=0.7500, minNodeSize=24.0000, targetView=3.0000 |
| ForestTypes | A1_woBIC_Joint | 本地消融结果 | best | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=100.0000, lambda=30.0000, lambdaBIC=0.0000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A3_SSETarget | 本地消融结果 | best | 625 | 1 | 10 | 6250 | best_mean_ACC_then_NMI | beta=200.0000, lambda=300.0000, lambdaBIC=0.2000, minNodeSize=20.0000, targetView=3.0000 |
| ForestTypes | A4_woMultiViewFusion | 本地消融结果 | best | 125 | 1 | 10 | 1250 | best_mean_ACC_then_NMI | beta=160.0000, lambda=Missing, lambdaBIC=0.2000, minNodeSize=16.0000, targetView=1.0000 |