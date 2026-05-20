# Caltech256 本地原始 3AMVC 运行结果

数据文件：catlch256_4Views_257cls_withClutter.mat
来源：D:\matlab\3AMVC-BIC\res\grid_search_caltech256_4views_257cls_withclutter_refined4_bestacc_detail.mat
选用依据：与 catlch256_4Views_257cls_withClutter 最相关、时间最新、网格最密集（81 组合）、指标字段完整。

---

## 最优结果

| 指标 | 值 |
|------|-----|
| ACC | 0.1807 |
| NMI | 0.4165 |
| AR | 0.1121 |
| Purity | 0.2353 |
| Fscore | 0.1171 |
| Precision | 0.1218 |
| Recall | 0.1128 |
| Entropy | 7.7531 |
| beta | 30 |
| lambda | 300000 |
| Anchor counts | [53, 70, 45, 79] |
| Target view | 1 |
| Total time | 78.6s |
| Iterations | 51 |

---

## 搜索网格

经过 4 轮逐步细化的网格搜索，最终在 refined4 的 81 组合（9x9）中确认最优为 beta=30, lambda=300000。

| 文件 | 网格规模 | 最优 beta | 最优 lambda | ACC |
|------|----------|-----------|-------------|-----|
| base | 4 | 10 | 100000 | 0.1735 |
| refined | 12 | 30 | 300000 | 0.1807 |
| refined2 | 12 | 30 | 300000 | 0.1807 |
| refined4 | 81 | 30 | 300000 | 0.1807 |

---

## 注意事项

- 该结果使用原始 HBNC 锚点生成（非 BIC-LR）
- 评价使用 numRuns=10 KMeans 重复，但锚点生成仅运行 1 次（seed=1）
- 与原论文 Caltech256 结果（ACC=0.1023）差异较大，原因是数据版本不同
- 本文使用的 catlch256_4Views_257cls_withClutter.mat 包含 257 类（含 clutter）
