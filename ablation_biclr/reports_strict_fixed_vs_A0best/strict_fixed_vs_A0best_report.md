# BIC-LR-3AMVC 严格固定参数消融分析：Strict Fixed vs A0-best

## 1. 实验结果读取情况
本报告读取 `ablation_biclr/res_strict_fixed` 中已完成的 strict fixed 消融结果，并以 `3AMVC-main/res_biclr_refined` 的 A0 best 结果作为参照。

| Dataset | Method | SourceFile | Status |
| --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\MFeat_2Views_BICLR_refined_best_ACC.mat | Found |
| Mfeat | A1_fixed_woBIC | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Mfeat\A1_fixed_woBIC_Mfeat_20260518_105222.mat | Found |
| Mfeat | A3_fixed_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Mfeat\A3_fixed_SSETarget_Mfeat_20260518_105651.mat | Found |
| Mfeat | A4_fixed_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Mfeat\A4_fixed_woMultiViewFusion_Mfeat_20260518_110037.mat | Found |
| Reuters-1200 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Reuters_1200_BICLR_refined_best_ACC.mat | Found |
| Reuters-1200 | A1_fixed_woBIC | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Reuters1200\A1_fixed_woBIC_Reuters1200_20260518_105611.mat | Found |
| Reuters-1200 | A3_fixed_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Reuters1200\A3_fixed_SSETarget_Reuters1200_20260518_110019.mat | Found |
| Reuters-1200 | A4_fixed_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Reuters1200\A4_fixed_woMultiViewFusion_Reuters1200_20260518_110152.mat | Found |
| WIKI | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Wikifea_BICLR_refined_best_ACC.txt | Found |
| WIKI | A1_fixed_woBIC | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\WIKI\A1_fixed_woBIC_WIKI_20260518_105144.mat | Found |
| WIKI | A3_fixed_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\WIKI\A3_fixed_SSETarget_WIKI_20260518_105624.mat | Found |
| WIKI | A4_fixed_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\WIKI\A4_fixed_woMultiViewFusion_WIKI_20260518_110029.mat | Found |
| ForestTypes | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\ForestTypes_BICLR_refined_best_ACC.mat | Found |
| ForestTypes | A1_fixed_woBIC | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\ForestTypes\A1_fixed_woBIC_ForestTypes_20260518_105603.mat | Found |
| ForestTypes | A3_fixed_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\ForestTypes\A3_fixed_SSETarget_ForestTypes_20260518_110009.mat | Found |
| ForestTypes | A4_fixed_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\ForestTypes\A4_fixed_woMultiViewFusion_ForestTypes_20260518_110145.mat | Found |
| Caltech256 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt | Found |
| Caltech256 | A1_fixed_woBIC | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Caltech256\A1_fixed_woBIC_Caltech256_20260518_105538.mat | Found |
| Caltech256 | A3_fixed_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Caltech256\A3_fixed_SSETarget_Caltech256_20260518_105907.mat | Found |
| Caltech256 | A4_fixed_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Caltech256\A4_fixed_woMultiViewFusion_Caltech256_20260518_110121.mat | Found |

读取完成：5 个数据集 × 3 个严格消融组均存在结果文件，未发现缺失项。

## 2. 对比口径与严格控制说明
- A0_Full_Reference 使用 `res_biclr_refined` 中的 best 值。
- A1/A3/A4 使用 fixed-parameter strict ablation 结果，不执行 grid search，主比较采用 strict mean±std。
- 报告同时给出 strict best-run 相对 A0-best 的辅助差值，便于区分评价随机性与模块影响。
- A1 只将 `lambdaBIC` 改为 0；A3 只改目标视图选择为 `SSEMin`；A4 只关闭多视图融合并记录 `lambdaNotUsed=true`。
- 由于 A0-best 是 best-run/summary 口径而 strict 主表是 mean 口径，均值差值是偏保守的模块观察，不应被写成 A0 mean 与 strict mean 的同口径结论。

## 3. 主性能表
| Dataset | A0-best | A1-fixed mean±std [best] | A3-fixed mean±std [best] | A4-fixed mean±std [best] |
| --- | --- | --- | --- | --- |
| Mfeat | 0.9270 / 0.8540 / 0.8452 | 0.8943±0.0497 / 0.8260±0.0314 / 0.7989±0.0576 [best 0.9270 / 0.8540 / 0.8452] | 0.8943±0.0497 / 0.8260±0.0314 / 0.7989±0.0576 [best 0.9270 / 0.8540 / 0.8452] | 0.5550±0.0444 / 0.5439±0.0312 / 0.3768±0.0465 [best 0.6295 / 0.5964 / 0.4420] |
| Reuters-1200 | 0.6592 / 0.4118 / 0.3748 | 0.5374±0.0290 / 0.3496±0.0114 / 0.2524±0.0281 [best 0.5783 / 0.3563 / 0.2662] | 0.5824±0.0395 / 0.3408±0.0196 / 0.2940±0.0298 [best 0.6275 / 0.3702 / 0.3330] | 0.6156±0.0128 / 0.3693±0.0083 / 0.3230±0.0142 [best 0.6317 / 0.3819 / 0.3427] |
| WIKI | 0.5820 / 0.5133 / Missing | 0.3761±0.0065 / 0.3486±0.0108 / 0.2158±0.0058 [best 0.3873 / 0.3342 / 0.2144] | 0.4710±0.0150 / 0.4250±0.0210 / 0.3189±0.0196 [best 0.4864 / 0.4421 / 0.3266] | 0.5394±0.0173 / 0.5080±0.0036 / 0.3407±0.0126 [best 0.5611 / 0.5115 / 0.3525] |
| ForestTypes | 0.8184 / 0.5530 / 0.5677 | 0.7157±0.0871 / 0.4291±0.0990 / 0.4221±0.1119 [best 0.8069 / 0.5311 / 0.5398] | 0.7585±0.0789 / 0.4859±0.0481 / 0.4857±0.0711 [best 0.8184 / 0.5530 / 0.5677] | 0.3034±0.0072 / 0.0131±0.0035 / 0.0065±0.0031 [best 0.3136 / 0.0196 / 0.0119] |
| Caltech256 | 0.3043 / 0.5379 / Missing | 0.3140±0.0028 / 0.5444±0.0026 / 0.2133±0.0034 [best 0.3180 / 0.5408 / 0.2181] | 0.0681±0.0004 / 0.2697±0.0005 / 0.0296±0.0009 [best 0.0686 / 0.2704 / 0.0307] | 0.0876±0.0025 / 0.3159±0.0011 / 0.0575±0.0029 [best 0.0912 / 0.3175 / 0.0592] |

## 4. Strict mean 相对 A0-best 的差值表
| Dataset | Method | CompareMode | Delta ACC | Delta NMI | Delta AR |
| --- | --- | --- | --- | --- | --- |
| Mfeat | A1_fixed_woBIC | Delta strict-mean vs A0-best | -0.0327 | -0.0280 | -0.0463 |
| Mfeat | A3_fixed_SSETarget | Delta strict-mean vs A0-best | -0.0327 | -0.0280 | -0.0463 |
| Mfeat | A4_fixed_woMultiViewFusion | Delta strict-mean vs A0-best | -0.3720 | -0.3101 | -0.4684 |
| Reuters-1200 | A1_fixed_woBIC | Delta strict-mean vs A0-best | -0.1218 | -0.0623 | -0.1224 |
| Reuters-1200 | A3_fixed_SSETarget | Delta strict-mean vs A0-best | -0.0768 | -0.0710 | -0.0808 |
| Reuters-1200 | A4_fixed_woMultiViewFusion | Delta strict-mean vs A0-best | -0.0435 | -0.0425 | -0.0518 |
| WIKI | A1_fixed_woBIC | Delta strict-mean vs A0-best | -0.2059 | -0.1647 | Missing |
| WIKI | A3_fixed_SSETarget | Delta strict-mean vs A0-best | -0.1110 | -0.0883 | Missing |
| WIKI | A4_fixed_woMultiViewFusion | Delta strict-mean vs A0-best | -0.0426 | -0.0053 | Missing |
| ForestTypes | A1_fixed_woBIC | Delta strict-mean vs A0-best | -0.1027 | -0.1240 | -0.1456 |
| ForestTypes | A3_fixed_SSETarget | Delta strict-mean vs A0-best | -0.0598 | -0.0672 | -0.0820 |
| ForestTypes | A4_fixed_woMultiViewFusion | Delta strict-mean vs A0-best | -0.5149 | -0.5399 | -0.5612 |
| Caltech256 | A1_fixed_woBIC | Delta strict-mean vs A0-best | +0.0097 | +0.0065 | Missing |
| Caltech256 | A3_fixed_SSETarget | Delta strict-mean vs A0-best | -0.2362 | -0.2682 | Missing |
| Caltech256 | A4_fixed_woMultiViewFusion | Delta strict-mean vs A0-best | -0.2167 | -0.2220 | Missing |

## 5. Strict best-run 相对 A0-best 的辅助差值表
| Dataset | Method | CompareMode | Delta ACC | Delta NMI | Delta AR |
| --- | --- | --- | --- | --- | --- |
| Mfeat | A1_fixed_woBIC | Delta strict-bestRun vs A0-best | +0.0000 | +0.0000 | -0.0000 |
| Mfeat | A3_fixed_SSETarget | Delta strict-bestRun vs A0-best | +0.0000 | +0.0000 | -0.0000 |
| Mfeat | A4_fixed_woMultiViewFusion | Delta strict-bestRun vs A0-best | -0.2975 | -0.2576 | -0.4032 |
| Reuters-1200 | A1_fixed_woBIC | Delta strict-bestRun vs A0-best | -0.0808 | -0.0555 | -0.1087 |
| Reuters-1200 | A3_fixed_SSETarget | Delta strict-bestRun vs A0-best | -0.0317 | -0.0416 | -0.0419 |
| Reuters-1200 | A4_fixed_woMultiViewFusion | Delta strict-bestRun vs A0-best | -0.0275 | -0.0299 | -0.0321 |
| WIKI | A1_fixed_woBIC | Delta strict-bestRun vs A0-best | -0.1947 | -0.1790 | Missing |
| WIKI | A3_fixed_SSETarget | Delta strict-bestRun vs A0-best | -0.0956 | -0.0712 | Missing |
| WIKI | A4_fixed_woMultiViewFusion | Delta strict-bestRun vs A0-best | -0.0209 | -0.0017 | Missing |
| ForestTypes | A1_fixed_woBIC | Delta strict-bestRun vs A0-best | -0.0115 | -0.0220 | -0.0278 |
| ForestTypes | A3_fixed_SSETarget | Delta strict-bestRun vs A0-best | -0.0000 | +0.0000 | -0.0000 |
| ForestTypes | A4_fixed_woMultiViewFusion | Delta strict-bestRun vs A0-best | -0.5048 | -0.5335 | -0.5557 |
| Caltech256 | A1_fixed_woBIC | Delta strict-bestRun vs A0-best | +0.0137 | +0.0029 | Missing |
| Caltech256 | A3_fixed_SSETarget | Delta strict-bestRun vs A0-best | -0.2357 | -0.2675 | Missing |
| Caltech256 | A4_fixed_woMultiViewFusion | Delta strict-bestRun vs A0-best | -0.2131 | -0.2204 | Missing |

## 6. A1 fixed w/o BIC 分析
- Mfeat：strict mean ACC/NMI/AR=0.8943±0.0497 / 0.8260±0.0314 / 0.7989±0.0576，相对 A0-best 的均值差值为 ACC=-0.0327，NMI=-0.0280，AR=-0.0463；strict best-run 差值为 ACC=+0.0000，NMI=+0.0000，AR=-0.0000；targetView=1，A0Target=1，BICTarget=1，SSETarget=1，anchors=[49 46]，acceptedSplits=[48 45]。
- Reuters-1200：strict mean ACC/NMI/AR=0.5374±0.0290 / 0.3496±0.0114 / 0.2524±0.0281，相对 A0-best 的均值差值为 ACC=-0.1218，NMI=-0.0623，AR=-0.1224；strict best-run 差值为 ACC=-0.0808，NMI=-0.0555，AR=-0.1087；targetView=3，A0Target=1，BICTarget=3，SSETarget=3，anchors=[60 62 64 62 62]，acceptedSplits=[59 61 63 61 61]。
- WIKI：strict mean ACC/NMI/AR=0.3761±0.0065 / 0.3486±0.0108 / 0.2158±0.0058，相对 A0-best 的均值差值为 ACC=-0.2059，NMI=-0.1647，AR=Missing；strict best-run 差值为 ACC=-0.1947，NMI=-0.1790，AR=Missing；targetView=2，A0Target=2，BICTarget=2，SSETarget=2，anchors=[73 75]，acceptedSplits=[72 74]。
- ForestTypes：strict mean ACC/NMI/AR=0.7157±0.0871 / 0.4291±0.0990 / 0.4221±0.1119，相对 A0-best 的均值差值为 ACC=-0.1027，NMI=-0.1240，AR=-0.1456；strict best-run 差值为 ACC=-0.0115，NMI=-0.0220，AR=-0.0278；targetView=3，A0Target=3，BICTarget=3，SSETarget=3，anchors=[17 17 18]，acceptedSplits=[16 16 17]。
- Caltech256：strict mean ACC/NMI/AR=0.3140±0.0028 / 0.5444±0.0026 / 0.2133±0.0034，相对 A0-best 的均值差值为 ACC=+0.0097，NMI=+0.0065，AR=Missing；strict best-run 差值为 ACC=+0.0137，NMI=+0.0029，AR=Missing；targetView=3，A0Target=3，BICTarget=3，SSETarget=1，anchors=[202 193 189 197]，acceptedSplits=[201 192 188 196]。
A1_fixed 只关闭 BIC 惩罚。若锚点数和 acceptedSplits 明显增加且 mean 性能下降，可作为 BIC 惩罚抑制过分裂的证据；若指标接近或提升，需要如实说明该数据集上 BIC 惩罚不是单调收益。

## 7. A3 fixed SSE Target 分析
- Mfeat：strict mean ACC/NMI/AR=0.8943±0.0497 / 0.8260±0.0314 / 0.7989±0.0576，相对 A0-best 的均值差值为 ACC=-0.0327，NMI=-0.0280，AR=-0.0463；strict best-run 差值为 ACC=+0.0000，NMI=+0.0000，AR=-0.0000；targetView=1，A0Target=1，BICTarget=1，SSETarget=1，anchors=[49 46]，acceptedSplits=[48 45]。
- Reuters-1200：strict mean ACC/NMI/AR=0.5824±0.0395 / 0.3408±0.0196 / 0.2940±0.0298，相对 A0-best 的均值差值为 ACC=-0.0768，NMI=-0.0710，AR=-0.0808；strict best-run 差值为 ACC=-0.0317，NMI=-0.0416，AR=-0.0419；targetView=3，A0Target=1，BICTarget=1，SSETarget=3，anchors=[41 42 47 38 47]，acceptedSplits=[40 41 46 37 46]。
- WIKI：strict mean ACC/NMI/AR=0.4710±0.0150 / 0.4250±0.0210 / 0.3189±0.0196，相对 A0-best 的均值差值为 ACC=-0.1110，NMI=-0.0883，AR=Missing；strict best-run 差值为 ACC=-0.0956，NMI=-0.0712，AR=Missing；targetView=1，A0Target=2，BICTarget=2，SSETarget=1，anchors=[15 35]，acceptedSplits=[14 34]。
- ForestTypes：strict mean ACC/NMI/AR=0.7585±0.0789 / 0.4859±0.0481 / 0.4857±0.0711，相对 A0-best 的均值差值为 ACC=-0.0598，NMI=-0.0672，AR=-0.0820；strict best-run 差值为 ACC=-0.0000，NMI=+0.0000，AR=-0.0000；targetView=3，A0Target=3，BICTarget=3，SSETarget=3，anchors=[17 17 16]，acceptedSplits=[16 16 15]。
- Caltech256：strict mean ACC/NMI/AR=0.0681±0.0004 / 0.2697±0.0005 / 0.0296±0.0009，相对 A0-best 的均值差值为 ACC=-0.2362，NMI=-0.2682，AR=Missing；strict best-run 差值为 ACC=-0.2357，NMI=-0.2675，AR=Missing；targetView=1，A0Target=3，BICTarget=3，SSETarget=1，anchors=[171 78 97 116]，acceptedSplits=[170 77 96 115]。
A3_fixed 只改变目标视图选择准则。targetView 改变且性能下降时，说明 BICUnitEvidence 在该数据集上更适合；targetView 不变时，该消融理论上不应改变主流程，差异主要来自评价随机性或缓存/运行细节。

## 8. A4 fixed w/o Multi-view Fusion 分析
- Mfeat：strict mean ACC/NMI/AR=0.5550±0.0444 / 0.5439±0.0312 / 0.3768±0.0465，相对 A0-best 的均值差值为 ACC=-0.3720，NMI=-0.3101，AR=-0.4684；strict best-run 差值为 ACC=-0.2975，NMI=-0.2576，AR=-0.4032；targetView=1，A0Target=1，BICTarget=1，SSETarget=1，anchors=[49 46]，acceptedSplits=[48 45]。
- Reuters-1200：strict mean ACC/NMI/AR=0.6156±0.0128 / 0.3693±0.0083 / 0.3230±0.0142，相对 A0-best 的均值差值为 ACC=-0.0435，NMI=-0.0425，AR=-0.0518；strict best-run 差值为 ACC=-0.0275，NMI=-0.0299，AR=-0.0321；targetView=1，A0Target=1，BICTarget=1，SSETarget=3，anchors=[41 42 47 38 47]，acceptedSplits=[40 41 46 37 46]。
- WIKI：strict mean ACC/NMI/AR=0.5394±0.0173 / 0.5080±0.0036 / 0.3407±0.0126，相对 A0-best 的均值差值为 ACC=-0.0426，NMI=-0.0053，AR=Missing；strict best-run 差值为 ACC=-0.0209，NMI=-0.0017，AR=Missing；targetView=2，A0Target=2，BICTarget=2，SSETarget=1，anchors=[15 35]，acceptedSplits=[14 34]。
- ForestTypes：strict mean ACC/NMI/AR=0.3034±0.0072 / 0.0131±0.0035 / 0.0065±0.0031，相对 A0-best 的均值差值为 ACC=-0.5149，NMI=-0.5399，AR=-0.5612；strict best-run 差值为 ACC=-0.5048，NMI=-0.5335，AR=-0.5557；targetView=3，A0Target=3，BICTarget=3，SSETarget=3，anchors=[17 17 16]，acceptedSplits=[16 16 15]。
- Caltech256：strict mean ACC/NMI/AR=0.0876±0.0025 / 0.3159±0.0011 / 0.0575±0.0029，相对 A0-best 的均值差值为 ACC=-0.2167，NMI=-0.2220，AR=Missing；strict best-run 差值为 ACC=-0.2131，NMI=-0.2204，AR=Missing；targetView=3，A0Target=3，BICTarget=3，SSETarget=1，anchors=[171 78 97 116]，acceptedSplits=[170 77 96 115]。
A4_fixed 只关闭跨视图对齐融合。若多个数据集出现明显下降，可视为多视图融合模块的最直接证据；若个别数据集下降较小，说明其目标视图单独已经具有较强判别信息。

## 9. 机制指标分析
| Dataset | Method | AnchorCounts | AvgAnchors | TargetView | A0TargetView | BICTargetView | SSETargetView | AcceptedSplits | RejectedSplits | MeanLeafSize | MaxDepth | AnchorTime | AlignmentTime | TotalTime | LambdaNotUsed | UseMultiViewFusion | CacheHit | CacheSource | SourceFile |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | A1_fixed_woBIC | [49 46] | 47.5 | 1 | 1 | 1 | 1 | [48 45] | [49 46] | [40.8163 43.4783] | [8 7] | 0 | 1.10037 | 1.52867 | false | true | [true true] | readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Mfeat\A1_fixed_woBIC_Mfeat_20260518_105222.mat |
| Mfeat | A3_fixed_SSETarget | [49 46] | 47.5 | 1 | 1 | 1 | 1 | [48 45] | [49 46] | [40.8163 43.4783] | [8 7] | 0 | 1.11534 | 1.49157 | false | true | [true true] | readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Mfeat\A3_fixed_SSETarget_Mfeat_20260518_105651.mat |
| Mfeat | A4_fixed_woMultiViewFusion | [49 46] | 47.5 | 1 | 1 | 1 | 1 | [48 45] | [49 46] | [40.8163 43.4783] | [8 7] | 0 | 0 | 0.608609 | true | false | [true true] | readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Mfeat\A4_fixed_woMultiViewFusion_Mfeat_20260518_110037.mat |
| Reuters-1200 | A1_fixed_woBIC | [60 62 64 62 62] | 62 | 3 | 1 | 3 | 3 | [59 61 63 61 61] | [60 62 64 62 62] | [20 19.3548 18.75 19.3548 19.3548] | [22 17 21 19 23] | 0 | 1.45985 | 1.88171 | false | true | [true true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Reuters1200\A1_fixed_woBIC_Reuters1200_20260518_105611.mat |
| Reuters-1200 | A3_fixed_SSETarget | [41 42 47 38 47] | 43 | 3 | 1 | 1 | 3 | [40 41 46 37 46] | [41 42 47 38 47] | [29.2683 28.5714 25.5319 31.5789 25.5319] | [12 15 14 15 23] | 0 | 1.30035 | 1.66947 | false | true | [true true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Reuters1200\A3_fixed_SSETarget_Reuters1200_20260518_110019.mat |
| Reuters-1200 | A4_fixed_woMultiViewFusion | [41 42 47 38 47] | 43 | 1 | 1 | 1 | 3 | [40 41 46 37 46] | [41 42 47 38 47] | [29.2683 28.5714 25.5319 31.5789 25.5319] | [12 15 14 15 23] | 0 | 0 | 0.567281 | true | false | [true true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Reuters1200\A4_fixed_woMultiViewFusion_Reuters1200_20260518_110152.mat |
| WIKI | A1_fixed_woBIC | [73 75] | 74 | 2 | 2 | 2 | 2 | [72 74] | [73 75] | [39.2603 38.2133] | [11 18] | 0 | 21.3251 | 22.2993 | false | true | [true true] | readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\WIKI\A1_fixed_woBIC_WIKI_20260518_105144.mat |
| WIKI | A3_fixed_SSETarget | [15 35] | 25 | 1 | 2 | 2 | 1 | [14 34] | [15 35] | [191.067 81.8857] | [6 11] | 0.474263 | 1.68656 | 2.57926 | false | true | [false false] | generated_without_cache_write; generated_without_cache_write | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\WIKI\A3_fixed_SSETarget_WIKI_20260518_105624.mat |
| WIKI | A4_fixed_woMultiViewFusion | [15 35] | 25 | 2 | 2 | 2 | 1 | [14 34] | [15 35] | [191.067 81.8857] | [6 11] | 0.222745 | 0 | 1.21806 | true | false | [false false] | generated_without_cache_write; generated_without_cache_write | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\WIKI\A4_fixed_woMultiViewFusion_WIKI_20260518_110029.mat |
| ForestTypes | A1_fixed_woBIC | [17 17 18] | 17.3333 | 3 | 3 | 3 | 3 | [16 16 17] | [17 17 18] | [30.7647 30.7647 29.0556] | [7 7 7] | 0 | 0.819977 | 0.969492 | false | true | [true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\ForestTypes\A1_fixed_woBIC_ForestTypes_20260518_105603.mat |
| ForestTypes | A3_fixed_SSETarget | [17 17 16] | 16.6667 | 3 | 3 | 3 | 3 | [16 16 15] | [17 17 16] | [30.7647 30.7647 32.6875] | [7 7 7] | 0 | 0.804738 | 0.895573 | false | true | [true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\ForestTypes\A3_fixed_SSETarget_ForestTypes_20260518_110009.mat |
| ForestTypes | A4_fixed_woMultiViewFusion | [17 17 16] | 16.6667 | 3 | 3 | 3 | 3 | [16 16 15] | [17 17 16] | [30.7647 30.7647 32.6875] | [7 7 7] | 0 | 0 | 0.212788 | true | false | [true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\ForestTypes\A4_fixed_woMultiViewFusion_ForestTypes_20260518_110145.mat |
| Caltech256 | A1_fixed_woBIC | [202 193 189 197] | 195.25 | 3 | 3 | 3 | 1 | [201 192 188 196] | [202 193 189 197] | [151.52 158.585 161.942 155.365] | [14 11 10 13] | 0 | 130.118 | 157.51 | false | true | [true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A1_fixed_woBIC\Caltech256\A1_fixed_woBIC_Caltech256_20260518_105538.mat |
| Caltech256 | A3_fixed_SSETarget | [171 78 97 116] | 115.5 | 1 | 3 | 3 | 1 | [170 77 96 115] | [171 78 97 116] | [178.988 392.397 315.536 263.853] | [13 8 8 11] | 0 | 99.508 | 130.185 | false | true | [true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A3_fixed_SSETarget\Caltech256\A3_fixed_SSETarget_Caltech256_20260518_105907.mat |
| Caltech256 | A4_fixed_woMultiViewFusion | [171 78 97 116] | 115.5 | 3 | 3 | 3 | 1 | [170 77 96 115] | [171 78 97 116] | [178.988 392.397 315.536 263.853] | [13 8 8 11] | 0 | 0 | 37.8593 | true | false | [true true true true] | readonly_existing_cache; readonly_existing_cache; readonly_existing_cache; readonly_existing_cache | D:\matlab\3AMVC-BIC\ablation_biclr\res_strict_fixed\A4_fixed_woMultiViewFusion\Caltech256\A4_fixed_woMultiViewFusion_Caltech256_20260518_110121.mat |

## 10. 固定配置与单变量控制检查
| Dataset | Method | FixedFrom | ChangedOnly | beta | lambda | lambdaBIC | minNodeSize | tauSplit | epsVar | numRuns | seed | A0TargetView | TargetView | StrictControlNote |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Mfeat | A1_fixed_woBIC | A0_best_res_biclr_refined | 仅关闭 BIC 复杂度惩罚：lambdaBIC 从 0.75 改为 0；不重新搜索参数。 | 100 | 1000 | 0 | 32 | 0 | 1e-08 | 10 | 1 | 1 | 1 | 只改 lambdaBIC=0；targetView=1 是关闭惩罚后的证据选择结果。 |
| Mfeat | A3_fixed_SSETarget | A0_best_res_biclr_refined | 仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。 | 100 | 1000 | 0.75 | 32 | 0 | 1e-08 | 10 | 1 | 1 | 1 | 只改 target rule；A0/BIC target=1，SSE target=1。 |
| Mfeat | A4_fixed_woMultiViewFusion | A0_best_res_biclr_refined | 仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。 | 100 | 1000 | 0.75 | 32 | 0 | 1e-08 | 10 | 1 | 1 | 1 | 只关融合；lambdaNotUsed=true，alignmentTime=0。 |
| Reuters-1200 | A1_fixed_woBIC | A0_best_res_biclr_refined | 仅关闭 BIC 复杂度惩罚：lambdaBIC 从 0.35 改为 0；不重新搜索参数。 | 2000 | 1000 | 0 | 16 | 0 | 1e-08 | 8 | 1 | 1 | 3 | 只改 lambdaBIC=0；targetView=3 是关闭惩罚后的证据选择结果。 |
| Reuters-1200 | A3_fixed_SSETarget | A0_best_res_biclr_refined | 仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。 | 2000 | 1000 | 0.35 | 16 | 0 | 1e-08 | 8 | 1 | 1 | 3 | 只改 target rule；A0/BIC target=1，SSE target=3。 |
| Reuters-1200 | A4_fixed_woMultiViewFusion | A0_best_res_biclr_refined | 仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。 | 2000 | 1000 | 0.35 | 16 | 0 | 1e-08 | 8 | 1 | 1 | 1 | 只关融合；lambdaNotUsed=true，alignmentTime=0。 |
| WIKI | A1_fixed_woBIC | A0_best_res_biclr_refined | 仅关闭 BIC 复杂度惩罚：lambdaBIC 从 4.5 改为 0；不重新搜索参数。 | 120 | 10000 | 0 | 30 | 0 | 1e-08 | 8 | 1 | 2 | 2 | 只改 lambdaBIC=0；targetView=2 是关闭惩罚后的证据选择结果。 |
| WIKI | A3_fixed_SSETarget | A0_best_res_biclr_refined | 仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。 | 120 | 10000 | 4.5 | 30 | 0 | 1e-08 | 8 | 1 | 2 | 1 | 只改 target rule；A0/BIC target=2，SSE target=1。 |
| WIKI | A4_fixed_woMultiViewFusion | A0_best_res_biclr_refined | 仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。 | 120 | 10000 | 4.5 | 30 | 0 | 1e-08 | 8 | 1 | 2 | 2 | 只关融合；lambdaNotUsed=true，alignmentTime=0。 |
| ForestTypes | A1_fixed_woBIC | A0_best_res_biclr_refined | 仅关闭 BIC 复杂度惩罚：lambdaBIC 从 0.75 改为 0；不重新搜索参数。 | 200 | 1000 | 0 | 24 | 0 | 1e-08 | 10 | 1 | 3 | 3 | 只改 lambdaBIC=0；targetView=3 是关闭惩罚后的证据选择结果。 |
| ForestTypes | A3_fixed_SSETarget | A0_best_res_biclr_refined | 仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。 | 200 | 1000 | 0.75 | 24 | 0 | 1e-08 | 10 | 1 | 3 | 3 | 只改 target rule；A0/BIC target=3，SSE target=3。 |
| ForestTypes | A4_fixed_woMultiViewFusion | A0_best_res_biclr_refined | 仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。 | 200 | 1000 | 0.75 | 24 | 0 | 1e-08 | 10 | 1 | 3 | 3 | 只关融合；lambdaNotUsed=true，alignmentTime=0。 |
| Caltech256 | A1_fixed_woBIC | A0_best_res_biclr_refined | 仅关闭 BIC 复杂度惩罚：lambdaBIC 从 3 改为 0；不重新搜索参数。 | 200 | 1000 | 0 | 120 | 0 | 1e-08 | 3 | 1 | 3 | 3 | 只改 lambdaBIC=0；targetView=3 是关闭惩罚后的证据选择结果。 |
| Caltech256 | A3_fixed_SSETarget | A0_best_res_biclr_refined | 仅将目标视图选择准则从 BICUnitEvidence 改为 SSEMin；不重新搜索参数。 | 200 | 1000 | 3 | 120 | 0 | 1e-08 | 3 | 1 | 3 | 1 | 只改 target rule；A0/BIC target=3，SSE target=1。 |
| Caltech256 | A4_fixed_woMultiViewFusion | A0_best_res_biclr_refined | 仅关闭多视图对齐融合，使用目标视图单视图锚图聚类；lambda 记录但不参与计算。 | 200 | 1000 | 3 | 120 | 0 | 1e-08 | 3 | 1 | 3 | 3 | 只关融合；lambdaNotUsed=true，alignmentTime=0。 |

## 11. 结论总结
严格固定参数结果显示：A1_fixed_woBIC 在 4/5 个数据集上 strict mean ACC 较 A0-best 下降超过 0.02；A3_fixed_SSETarget 在 5/5 个数据集上 strict mean ACC 较 A0-best 下降超过 0.02；A4_fixed_woMultiViewFusion 在 5/5 个数据集上 strict mean ACC 较 A0-best 下降超过 0.02。明显下降项包括：Mfeat/A4_fixed_woMultiViewFusion(Delta ACC=-0.3720)；Reuters-1200/A1_fixed_woBIC(Delta ACC=-0.1218)；WIKI/A1_fixed_woBIC(Delta ACC=-0.2059)；WIKI/A3_fixed_SSETarget(Delta ACC=-0.1110)；ForestTypes/A1_fixed_woBIC(Delta ACC=-0.1027)；ForestTypes/A4_fixed_woMultiViewFusion(Delta ACC=-0.5149)；Caltech256/A3_fixed_SSETarget(Delta ACC=-0.2362)；Caltech256/A4_fixed_woMultiViewFusion(Delta ACC=-0.2167)。A4_fixed 在 Mfeat、ForestTypes 和 Caltech256 上下降最明显，是多视图融合必要性的主要证据。A3_fixed 在 Caltech256 和 WIKI 上 targetView 改变后性能明显下降，说明目标视图选择准则具有数据集依赖性。A1_fixed 的影响不完全单调，Caltech256 等数据集出现 strict mean 高于 A0-best 的情况，应作为数据集依赖现象报告。
strict mean 高于 A0-best 的项目包括：Caltech256/A1_fixed_woBIC(Delta ACC=+0.0097)。