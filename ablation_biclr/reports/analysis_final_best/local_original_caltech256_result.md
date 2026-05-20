# Caltech256 本地原始 3AMVC baseline（best 口径）

本表只用于 Caltech256 的原始 3AMVC 对比。由于当前 Caltech256 数据由用户自行处理，论文报告的 Caltech256 指标不作为正式 baseline。

选用 baseline 文件：`D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined4_bestacc_detail.mat`。
选用依据：与 `catlch256_4Views_257cls_withClutter` 最相关、时间最新且指标字段完整。

| Dataset | Source | File | ACC_mean | ACC_std | NMI_mean | NMI_std | AR_mean | AR_std | Purity_mean | Fscore_mean | Precision_mean | Recall_mean | Entropy_mean | Selected_beta | Selected_lambda | SelectedTargetView | AnchorCounts | LastWriteTime | Chosen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Caltech256 | Original 3AMVC local run on catlch256_4Views_257cls_withClutter | D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_bestacc_detail.mat | 0.173522 | 0 | 0.41619 | 0 | 0.105488 | 0 | 0.222175 | 0.110889 | 0.107844 | 0.114174 | 7.62892 | 10 | 100000 | Missing |  | 740117 | 0 |
| Caltech256 | Original 3AMVC local run on catlch256_4Views_257cls_withClutter | D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined2_bestacc_detail.mat | 0.18074 | 0 | 0.416494 | 0 | 0.112127 | 0 | 0.235306 | 0.117138 | 0.121842 | 0.112803 | 7.75315 | 30 | 300000 | 1 | 53,70,45,79 | 740117 | 0 |
| Caltech256 | Original 3AMVC local run on catlch256_4Views_257cls_withClutter | D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined4_bestacc_detail.mat | 0.18074 | 0 | 0.416494 | 0 | 0.112127 | 0 | 0.235306 | 0.117138 | 0.121842 | 0.112803 | 7.75315 | 30 | 300000 | 1 | 53,70,45,79 | 740117 | 1 |
| Caltech256 | Original 3AMVC local run on catlch256_4Views_257cls_withClutter | D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined_bestacc_detail.mat | 0.18074 | 0 | 0.416494 | 0 | 0.112127 | 0 | 0.235306 | 0.117138 | 0.121842 | 0.112803 | 7.75315 | 30 | 300000 | Missing |  | 740117 | 0 |