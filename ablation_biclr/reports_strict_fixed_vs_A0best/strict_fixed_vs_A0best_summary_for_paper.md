# Strict fixed ablation 补充比较摘要

为避免各消融变体各自网格搜索带来的混杂因素，我们进一步采用 fixed-parameter strict ablation：对每个数据集固定 A0 best 的 `beta`、`lambda`、`lambdaBIC`、`minNodeSize`、随机种子和评价次数，只改变一个模块。下述比较以 A0-best 为参照，strict 消融主指标采用 mean±std，同时记录 best-run 作为辅助观察。

A1_fixed_woBIC 的 strict mean 相对 A0-best 差值为：Mfeat: Delta ACC=-0.0327, Delta NMI=-0.0280, Delta AR=-0.0463；Reuters-1200: Delta ACC=-0.1218, Delta NMI=-0.0623, Delta AR=-0.1224；WIKI: Delta ACC=-0.2059, Delta NMI=-0.1647, Delta AR=Missing；ForestTypes: Delta ACC=-0.1027, Delta NMI=-0.1240, Delta AR=-0.1456；Caltech256: Delta ACC=+0.0097, Delta NMI=+0.0065, Delta AR=Missing。
A3_fixed_SSETarget 的 strict mean 相对 A0-best 差值为：Mfeat: Delta ACC=-0.0327, Delta NMI=-0.0280, Delta AR=-0.0463；Reuters-1200: Delta ACC=-0.0768, Delta NMI=-0.0710, Delta AR=-0.0808；WIKI: Delta ACC=-0.1110, Delta NMI=-0.0883, Delta AR=Missing；ForestTypes: Delta ACC=-0.0598, Delta NMI=-0.0672, Delta AR=-0.0820；Caltech256: Delta ACC=-0.2362, Delta NMI=-0.2682, Delta AR=Missing。
A4_fixed_woMultiViewFusion 的 strict mean 相对 A0-best 差值为：Mfeat: Delta ACC=-0.3720, Delta NMI=-0.3101, Delta AR=-0.4684；Reuters-1200: Delta ACC=-0.0435, Delta NMI=-0.0425, Delta AR=-0.0518；WIKI: Delta ACC=-0.0426, Delta NMI=-0.0053, Delta AR=Missing；ForestTypes: Delta ACC=-0.5149, Delta NMI=-0.5399, Delta AR=-0.5612；Caltech256: Delta ACC=-0.2167, Delta NMI=-0.2220, Delta AR=Missing。

总体上，关闭多视图融合的 A4_fixed 在多个数据集上造成最稳定的性能下降，说明跨视图对齐融合是完整模型的重要组成部分。A1_fixed 和 A3_fixed 的影响更依赖数据集；特别是当目标视图没有改变或 BIC 惩罚改变未导致明显过分裂时，指标可能接近 A0。由于 A0 参照为 best 口径，而 strict 主结果为 mean 口径，论文中应明确该表为固定参数补充分析，不应与 A0 mean 同口径结果混写。