# A0-best vs Ablation-mean 公平性限制说明

本文件专门说明混合口径比较的限制。

1. A0 使用 best 值，A1/A3/A4 使用 mean 值，因此该报告不是严格同口径比较。
2. A0 来源于 `3AMVC-main/res_biclr_refined`，消融组来源于 `ablation_biclr/res`，结果结构和字段完整度不同。
3. 各消融组此前采用各自网格选优，参数并未固定为 A0 best 配置。
4. A4 不使用多视图融合，lambda 不参与计算，因此它的搜索空间天然不同。
5. Caltech256 当前为 257 类含 clutter 的本地处理版本，不能直接采用原论文 Caltech256 指标作为正式 baseline。
6. A0 旧结果中部分机制字段缺失，机制分析主要依赖 A1/A3/A4 的统一结果字段。

因此，该报告只能作为完整模型最优潜力与消融变体平均表现之间的补充观察。严格单变量结论应以后续 fixed-parameter strict ablation 为准。

## 读取文件
| Dataset | Method | SourceFile | Status |
| --- | --- | --- | --- |
| Mfeat | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\MFeat_2Views_BICLR_refined_best_ACC.mat | Found |
| Mfeat | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Mfeat\A1_woBIC_Joint_Mfeat_latest.mat | Found |
| Mfeat | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Mfeat\A3_SSETarget_Mfeat_latest.mat | Found |
| Mfeat | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Mfeat\A4_woMultiViewFusion_Mfeat_latest.mat | Found |
| Reuters-1200 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Reuters_1200_BICLR_refined_best_ACC.mat | Found |
| Reuters-1200 | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Ruter1200\A1_woBIC_Joint_Ruter1200_latest.mat | Found |
| Reuters-1200 | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Ruter1200\A3_SSETarget_Ruter1200_latest.mat | Found |
| Reuters-1200 | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Ruter1200\A4_woMultiViewFusion_Ruter1200_latest.mat | Found |
| WIKI | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Wikifea_BICLR_refined_best_ACC.txt | Found |
| WIKI | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\WIKI\A1_woBIC_Joint_WIKI_latest.mat | Found |
| WIKI | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\WIKI\A3_SSETarget_WIKI_latest.mat | Found |
| WIKI | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\WIKI\A4_woMultiViewFusion_WIKI_latest.mat | Found |
| ForestTypes | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\ForestTypes_BICLR_refined_best_ACC.mat | Found |
| ForestTypes | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\ForestTypes\A1_woBIC_Joint_ForestTypes_latest.mat | Found |
| ForestTypes | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\ForestTypes\A3_SSETarget_ForestTypes_latest.mat | Found |
| ForestTypes | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\ForestTypes\A4_woMultiViewFusion_ForestTypes_latest.mat | Found |
| Caltech256 | A0_Full_Reference | D:\matlab\3AMVC-BIC\3AMVC-main\res_biclr_refined\Caltech256_4Views_257cls_withClutter_BICLR_refined_best_ACC.txt | Found |
| Caltech256 | A1_woBIC_Joint | D:\matlab\3AMVC-BIC\ablation_biclr\res\A1_woBIC_Joint\Caltech256_4Views_257cls_withClutter\A1_woBIC_Joint_Caltech256_4Views_257cls_withClutter_latest.mat | Found |
| Caltech256 | A3_SSETarget | D:\matlab\3AMVC-BIC\ablation_biclr\res\A3_SSETarget\Caltech256_4Views_257cls_withClutter\A3_SSETarget_Caltech256_4Views_257cls_withClutter_latest.mat | Found |
| Caltech256 | A4_woMultiViewFusion | D:\matlab\3AMVC-BIC\ablation_biclr\res\A4_woMultiViewFusion\Caltech256_4Views_257cls_withClutter\A4_woMultiViewFusion_Caltech256_4Views_257cls_withClutter_latest.mat | Found |