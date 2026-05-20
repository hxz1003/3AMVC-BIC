# Strict fixed vs A0-best 口径说明

本报告比各变体各自网格消融更接近单变量控制，因为 strict 消融固定 A0 best 配置且不重新搜索参数。

仍需注意：
- A0 参照使用 best 值，strict 主表使用 mean±std，因此主差值不是 A0 mean vs strict mean 的完全同口径比较。
- strict best-run 辅助表仅用于观察评价随机性，不应替代 mean±std 作为稳定结论。
- Caltech256 是 257 类含 clutter 的本地处理版本，不能直接套用原论文 Caltech256 指标。
- A1 中 targetView 的变化是 `lambdaBIC=0` 改变视图证据后的下游结果，不是额外手动改动目标视图规则。
- A4 中 `lambda` 被记录但不参与单视图聚类，报告中以 `lambdaNotUsed=true` 标注。

## 读取文件
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