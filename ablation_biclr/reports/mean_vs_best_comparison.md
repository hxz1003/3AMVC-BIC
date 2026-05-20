# Mean vs Best 结果口径对比

## 1. 两种口径定义
- mean 口径：使用 selectedConfig 下多次运行的平均指标，更适合作为论文主结果。
- best 口径：使用完整实验中可识别的单次或单配置最高指标，更适合补充说明模型潜力，但不应替代 mean 作为主结果。
- 本对比中 A0_Full 的正式来源均为 `3AMVC-main/res_biclr_refined`。

## 2. A0_Full mean 与 best 对比表
| Dataset | A0 mean ACC/NMI/AR | A0 best ACC/NMI/AR | Best - Mean ACC | Best - Mean NMI | Best - Mean AR |
| --- | --- | --- | --- | --- | --- |
| Mfeat | 0.8943 / 0.8260 / 0.7989 | 0.9270 / 0.8540 / 0.8452 | 0.0327 | 0.0279814 | 0.0462937 |
| Reuters-1200 | 0.6481 / 0.3977 / 0.3571 | 0.6592 / 0.4118 / 0.3748 | 0.0110417 | 0.0140788 | 0.0176857 |
| WIKI | 0.5579 / 0.5204 / Missing | 0.5820 / 0.5133 / Missing | 0.024119 | -0.007131 | Missing |
| Caltech256 | 0.3043 / 0.5379 / Missing | 0.3043 / 0.5379 / Missing | 0 | 0 | Missing |
| ForestTypes | 0.7585 / 0.4859 / 0.4857 | 0.8184 / 0.5530 / 0.5677 | 0.059847 | 0.067167 | 0.0819725 |

## 3. 消融结论是否一致
### A0 vs A1_woBIC_Joint
- Mfeat：mean ΔACC=+0.0047，best ΔACC=+0.0000，方向一致。
- Reuters-1200：mean ΔACC=-0.0876，best ΔACC=-0.0483，方向一致。
- WIKI：mean ΔACC=-0.0187，best ΔACC=+0.0035，方向一致。
- Caltech256：mean ΔACC=+0.0145，best ΔACC=+0.0178，方向一致。
- ForestTypes：mean ΔACC=+0.0262，best ΔACC=+0.0019，方向不一致。
### A0 vs A3_SSETarget
- Mfeat：mean ΔACC=+0.0047，best ΔACC=+0.0000，方向一致。
- Reuters-1200：mean ΔACC=-0.0525，best ΔACC=-0.0167，方向不一致。
- WIKI：mean ΔACC=+0.0225，best ΔACC=+0.0059，方向不一致。
- Caltech256：mean ΔACC=-0.0599，best ΔACC=-0.0519，方向一致。
- ForestTypes：mean ΔACC=+0.0455，best ΔACC=+0.0191，方向不一致。
### A0 vs A4_woMultiViewFusion
- Mfeat：mean ΔACC=-0.3106，best ΔACC=-0.2410，方向一致。
- Reuters-1200：mean ΔACC=-0.0376，best ΔACC=-0.0392，方向一致。
- WIKI：mean ΔACC=-0.0033，best ΔACC=+0.0147，方向一致。
- Caltech256：mean ΔACC=-0.2154，best ΔACC=-0.2130，方向一致。
- ForestTypes：mean ΔACC=-0.0807，best ΔACC=-0.0765，方向一致。
### A0 vs Original baseline
- Mfeat：mean ΔACC=+0.0206，best ΔACC=+0.0533，方向一致。
- Reuters-1200：mean ΔACC=+0.0747，best ΔACC=+0.0858，方向一致。
- WIKI：mean ΔACC=Missing，best ΔACC=Missing，方向无法判断。
- Caltech256：mean ΔACC=+0.1236，best ΔACC=+0.1236，方向一致。
- ForestTypes：mean ΔACC=-0.0399，best ΔACC=+0.0200，方向不一致。

## 4. 如果结论不一致
- 若 mean 口径下 A0 优于某消融变体，但 best 口径下该变体接近或超过 A0，可能来自随机初始化波动、参数网格中的高方差配置，或该数据集对该模块不敏感。
- 若 best 值明显高于 mean 值，应将其标记为偶然最优风险，不能直接作为稳定性能证据。
- Caltech256 A0 文本未包含逐次 bestRun 指标，本次按用户指定采用 refined best_ACC 文本中的最好均值摘要，因此应在 best 口径表中标注其并非逐次最优运行值。

## 5. 建议论文采用口径
- 论文主表建议采用 mean 口径。
- best 口径可以放在附录或补充分析中。
- 如果正文使用 best 口径，必须说明其为最佳运行结果，而不是多次重复平均结果。