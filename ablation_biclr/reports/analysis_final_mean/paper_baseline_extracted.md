# 原论文与补充材料信息提取（mean 口径）

- 原论文 PDF：`D:\matlab\3AMVC-BIC\3664647.3681273.pdf`
- 补充材料 PDF：`D:\matlab\3AMVC-BIC\The_Name_of_the_Title_is_Hope (1).pdf`
- PDF 读取状态：原论文=1，补充材料=1
- 表格抽取说明：PDF table extraction incomplete; manual verification needed.

## 实验设置
- 数据集：ForestTypes、Reuters、MFeat、Caltech256、VGGFace2。
- 指标：ACC, NMI, Fscore。
- 参数范围：3AMVC 调整 beta 到 [10^-2, 1, 10^2]，lambda 到 [0, 10^-4, 10^-2, 1, 10^4]。
- 方法口径：原始 3AMVC 使用 HBNC 生成各视图自适应锚点；使用 Eq.(8) 的簇内距离质量准则选择 baseline view；将其他视图锚图对齐到 baseline view 后做等权融合并谱聚类。

## 结构化提取表
| Dataset | Samples | Clusters | Views | ACC | NMI | AR | Purity | Fscore | PaperBaselineView | HBNCAnchorCounts | Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ForestTypes | 523 | 4 | 3 | 0.7984 | 0.5397 | Missing | Missing | 0.6752 | 3 | [10 16 20] | Paper reported 3AMVC |
| Reuters-1200 | 1200 | 6 | 5 | 0.5734 | 0.3316 | Missing | Missing | 0.4061 | 5 | [62 48 45 13 53] | Paper reported 3AMVC |
| Mfeat | 2000 | 10 | 2 | 0.8737 | 0.824 | Missing | Missing | 0.7986 | 1 | [54 64] | Paper reported 3AMVC |
| Caltech256 | 30607 | 256 | 4 | 0.1023 | 0.321 | Missing | Missing | 0.0792 | 3 | [48 67 62 45] | Paper reported 3AMVC; reference only for current Caltech256 |
| VGGFace2 | 36287 | 100 | 4 | Missing | Missing | Missing | Missing | Missing | Missing |  | Paper dataset setting |