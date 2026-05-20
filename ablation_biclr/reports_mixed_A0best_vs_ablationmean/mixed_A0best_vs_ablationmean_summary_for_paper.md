# A0-best vs Ablation-mean 补充比较摘要

作为补充分析，我们将完整模型 A0 在 refined 搜索中的 best 结果与消融变体 A1/A3/A4 的 mean 结果进行比较。需要强调的是，该设置采用 A0-best vs ablation-mean 的混合口径，并非严格同口径、固定参数的单变量消融，因此结果主要反映完整模型最优潜力与各消融变体平均表现之间的差异，不能直接作为严格因果结论。

对于 A1_woBIC_Joint，混合口径差值为：Mfeat: Delta ACC=-0.0280, Delta NMI=-0.0307, Delta AR=-0.0486；Reuters-1200: Delta ACC=-0.0986, Delta NMI=-0.0738, Delta AR=-0.1079；WIKI: Delta ACC=-0.0428, Delta NMI=-0.0036, Delta AR=Missing；ForestTypes: Delta ACC=-0.0337, Delta NMI=-0.0589, Delta AR=-0.0517；Caltech256: Delta ACC=+0.0145, Delta NMI=+0.0180, Delta AR=Missing。
对于 A3_SSETarget，混合口径差值为：Mfeat: Delta ACC=-0.0280, Delta NMI=-0.0307, Delta AR=-0.0486；Reuters-1200: Delta ACC=-0.0635, Delta NMI=-0.0499, Delta AR=-0.0791；WIKI: Delta ACC=-0.0017, Delta NMI=+0.0117, Delta AR=Missing；ForestTypes: Delta ACC=-0.0143, Delta NMI=-0.0377, Delta AR=-0.0195；Caltech256: Delta ACC=-0.0599, Delta NMI=-0.0565, Delta AR=Missing。
对于 A4_woMultiViewFusion，混合口径差值为：Mfeat: Delta ACC=-0.3433, Delta NMI=-0.3193, Delta AR=-0.4437；Reuters-1200: Delta ACC=-0.0486, Delta NMI=-0.0656, Delta AR=-0.0645；WIKI: Delta ACC=-0.0274, Delta NMI=-0.0023, Delta AR=Missing；ForestTypes: Delta ACC=-0.1405, Delta NMI=-0.1759, Delta AR=-0.2147；Caltech256: Delta ACC=-0.2154, Delta NMI=-0.2222, Delta AR=Missing。

总体而言，A4 w/o Multi-view Fusion 在多数数据集上相对 A0-best 出现更稳定的下降，说明跨视图对齐融合是较强的性能来源。A1 w/o BIC 与 A3 SSE Target 的表现更依赖数据集和搜索口径，个别数据集可能接近或超过 A0-best，因此论文中应将该表述限定为补充观察，并配合 fixed-parameter strict ablation 给出更严格的单变量验证。