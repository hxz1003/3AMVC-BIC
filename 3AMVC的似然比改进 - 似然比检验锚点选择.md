**ChatGPT:**

我会把符号也统一为论文中常见的 $Z^{(v)}\in\mathbb{R}^{n\times m_v}$ 记法，这样 3.7 的等权融合可以直接写成 $Z^{(b)}+\sum Z^{(v)}P_v$ 的形式，避免行列方向混乱。

* * *

**ChatGPT:**

下面给出修订后的完整 **Proposed Method**。相比上一版，主要改动为：

1. **删除原 3.7 中“质量—对齐感知加权融合”部分**，改为 3AMVC 论文中的 **等权融合**；
2. **扩展 3.3.2**，详细写出单簇假设、双簇假设、似然函数、对数似然、极大似然估计以及 BIC 正则化似然比准则；
3. 其余框架保持不变，不加入源代码描述，不出现具体程序函数名。

---

# 3. Proposed Method

## 3.1 问题定义

给定一个包含 $V$ 个视图的多视图数据集：

$$\mathcal{X}=\{X^{(v)}\}_{v=1}^{V},$$

其中第 $v$ 个视图表示为：

$$X^{(v)}  
=  
\left[  
x_1^{(v)},x_2^{(v)},\ldots,x_n^{(v)}  
\right]^\top  
\in \mathbb{R}^{n\times d_v}.$$

这里，$n$ 表示样本数，$d_v$ 表示第 $v$ 个视图的特征维度，$x_i^{(v)}\in\mathbb{R}^{d_v}$ 表示第 $i$ 个样本在第 $v$ 个视图下的特征表示。多视图聚类的目标是在没有监督标签的情况下，学习一个统一的聚类划分：

$$\mathcal{Y}=\{y_i\}_{i=1}^{n},  
\qquad  
y_i\in\{1,2,\ldots,K\},$$

其中 $K$ 表示聚类类别数。

锚图多视图聚类的基本思想是：不直接构造完整的 $n\times n$ 样本相似图，而是在每个视图中选取较少数量的代表性锚点，并通过样本—锚点关系近似原始样本图结构。3AMVC 论文指出，锚图方法能够有效降低完整图构造中的二次复杂度，使多视图聚类能够适应大规模数据场景。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

对于第 $v$ 个视图，本文需要自动学习一组锚点：

$$\Theta^{(v)}  
=  
\left\{  
\theta_1^{(v)},\theta_2^{(v)},\ldots,\theta_{m_v}^{(v)}  
\right\},$$

其中 $m_v$ 表示第 $v$ 个视图自动生成的锚点数。与预先固定所有视图锚点数的方法不同，本文允许不同视图具有不同数量的锚点，即：

$$m_1\neq m_2\neq\cdots\neq m_V.$$

这与 3AMVC 的基本动机一致。3AMVC 认为，强制不同视图具有相同数量的锚点会限制各视图自身的表示能力，因此需要一种能够为每个视图自适应确定锚点数量的机制。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

## 3.2 总体框架

本文方法沿用 3AMVC 的整体框架，即：

$$X^{(v)}  
\longrightarrow  
\Theta^{(v)}  
\longrightarrow  
Z^{(v)}  
\longrightarrow  
\widetilde Z^{(v)}  
\longrightarrow  
Z_{\mathrm{aligned}}  
\longrightarrow  
\mathcal{Y}.$$

整个方法由五个主要阶段组成。

第一，对每个视图独立执行 **基于 BIC 正则化似然比检验的自适应锚点选择**，得到视图特定的锚点集合 $\Theta^{(v)}$。

第二，基于锚点集合构造每个视图的样本—锚点关系矩阵 $Z^{(v)}$。

第三，根据单视图锚点质量选择基准视图 $b$。

第四，将其他视图的锚图对齐到基准视图，得到对齐后的锚图 $\widetilde Z^{(v)}$。

第五，对所有对齐后的锚图执行等权融合，得到统一的融合锚图 $Z_{\mathrm{aligned}}$，再通过谱嵌入与聚类得到最终结果。

3AMVC 论文中的总体框架同样包括三个核心步骤：首先在各视图中自动选择代表性锚点，其次根据锚图质量选择基准视图并对齐其他视图，最后融合对齐后的锚图并进行聚类。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

# 3.3 基于 BIC 正则化似然比检验的自适应锚点选择

## 3.3.1 局部节点建模

对于第 $v$ 个视图中的任意当前节点，记其样本集合为：

$$C=\{x_i^{(v)}\mid i\in\mathcal{I}_C\}.$$

其中，$\mathcal{I}_C$ 表示属于当前节点的样本索引集合，节点样本数为：

$$n_C=|C|.$$

为简化记号，在本节中省略视图上标 $(v)$，将样本记为：

$$x_i\in\mathbb{R}^{d}.$$

当前节点 $C$ 的均值中心定义为：

$$\mu_C  
=  
\frac{1}{n_C}  
\sum_{x_i\in C}x_i.  
\tag{1}$$

其簇内平方误差定义为：

$$W(C)  
=  
\sum_{x_i\in C}  
\left\|  
x_i-\mu_C  
\right\|_2^2.  
\tag{2}$$

该项用于衡量当前节点内部样本围绕中心的紧凑程度。3AMVC 原文在讨论 HBNC 停止准则时，也将样本到簇中心的距离作为评价簇中心代表性的重要依据：簇内样本越接近其中心，簇中心作为锚点的代表性越强。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

## 3.3.2 单簇假设、双簇假设与似然估计

对于当前节点 $C$，本文将“是否继续划分”转化为一个局部统计模型选择问题。具体地，考虑如下两个竞争假设：

$$H_0:\ C\ \text{由一个球形高斯分布生成},$$ $$H_1:\ C\ \text{由两个共享方差的球形高斯子分布生成}.$$

其中，$H_0$ 表示当前节点内部已经足够紧凑，不需要继续生成新的锚点；$H_1$ 表示当前节点内部仍然存在可分结构，应当继续二分，从而产生更多局部锚点。

---

### 3.3.2.1 零假设下的单簇似然函数

在零假设 $H_0$ 下，假设当前节点 $C$ 中所有样本均由同一个球形高斯分布生成：

$$x_i\sim \mathcal{N}(\mu_0,\sigma_0^2 I_d),  
\qquad  
x_i\in C.  
\tag{3}$$

其中，$\mu_0\in\mathbb{R}^{d}$ 为均值向量，$\sigma_0^2$ 为球形方差，$I_d$ 为 $d$ 维单位矩阵。

对于单个样本 $x_i$，其概率密度为：

$$p(x_i\mid \mu_0,\sigma_0^2)  
=  
\frac{1}{(2\pi\sigma_0^2)^{d/2}}  
\exp  
\left(  
-\frac{  
\|x_i-\mu_0\|_2^2  
}{  
2\sigma_0^2  
}  
\right).  
\tag{4}$$

由于节点内样本被假设为独立同分布，因此当前节点在 $H_0$ 下的似然函数为：

$$L_0(C\mid \mu_0,\sigma_0^2)  
=  
\prod_{x_i\in C}  
p(x_i\mid \mu_0,\sigma_0^2).  
\tag{5}$$

将式 $(4)$ 代入式 $(5)$，得到：

$$L_0(C\mid \mu_0,\sigma_0^2)  
=  
\prod_{x_i\in C}  
\frac{1}{(2\pi\sigma_0^2)^{d/2}}  
\exp  
\left(  
-\frac{  
\|x_i-\mu_0\|_2^2  
}{  
2\sigma_0^2  
}  
\right).  
\tag{6}$$

对式 $(6)$ 取对数，可得零假设下的对数似然函数：

$$\ell_0(C\mid \mu_0,\sigma_0^2)  
=  
-\frac{n_Cd}{2}\log(2\pi)  
-  
\frac{n_Cd}{2}\log\sigma_0^2  
-  
\frac{1}{2\sigma_0^2}  
\sum_{x_i\in C}  
\|x_i-\mu_0\|_2^2.  
\tag{7}$$

为了获得最大似然估计，对 $\mu_0$ 求导并令其为零，可得到：

$$\hat{\mu}_0  
=  
\frac{1}{n_C}  
\sum_{x_i\in C}x_i  
=  
\mu_C.  
\tag{8}$$

再对 $\sigma_0^2$ 求导并令其为零，可得到：

$$\hat{\sigma}_0^2  
=  
\frac{1}{n_Cd}  
\sum_{x_i\in C}  
\left\|  
x_i-\hat{\mu}_0  
\right\|_2^2.  
\tag{9}$$

结合式 $(2)$，式 $(9)$ 可写为：

$$\hat{\sigma}_0^2  
=  
\frac{W(C)}{n_Cd}.  
\tag{10}$$

为避免节点内部样本完全重合时出现方差退化，引入一个极小正数 $\varepsilon>0$，得到稳定形式：

$$\hat{\sigma}_0^2  
=  
\frac{W(C)}{n_Cd}  
+  
\varepsilon.  
\tag{11}$$

将式 $(8)$ 和式 $(11)$ 代入式 $(7)$，可得单簇模型的极大对数似然：

$$\ell_0(C)  
=  
-\frac{n_Cd}{2}  
\left[  
\log(2\pi\hat{\sigma}_0^2)+1  
\right].  
\tag{12}$$

式 $(3)$–$(12)$ 给出了单簇假设下的完整似然估计过程。其含义是：若当前节点中的样本能够被一个均值中心和一个共享球形方差较好解释，则继续划分该节点的必要性较弱。

---

### 3.3.2.2 备择假设下的双簇似然函数

在备择假设 $H_1$ 下，当前节点 $C$ 被划分为两个子节点：

$$C\rightarrow C_1\cup C_2,  
\qquad  
C_1\cap C_2=\varnothing.  
\tag{13}$$

记两个子节点的样本数分别为：

$$n_1=|C_1|,  
\qquad  
n_2=|C_2|,  
\qquad  
n_1+n_2=n_C.  
\tag{14}$$

双簇模型假设两个子簇分别服从不同均值但共享方差的球形高斯分布：

$$x_i\mid x_i\in C_g  
\sim  
\mathcal{N}(\mu_g,\sigma_{12}^2 I_d),  
\qquad  
g=1,2.  
\tag{15}$$

其中，$\mu_1,\mu_2\in\mathbb{R}^{d}$ 分别表示两个子簇的均值向量，$\sigma_{12}^2$ 表示两个子簇共享的球形方差。

两个子簇的混合比例定义为：

$$\pi_1=\frac{n_1}{n_C},  
\qquad  
\pi_2=\frac{n_2}{n_C},  
\qquad  
\pi_1+\pi_2=1.  
\tag{16}$$

若给定当前候选划分 $C_1,C_2$，则双簇模型的似然函数可写为：

$$L_1(C_1,C_2\mid \mu_1,\mu_2,\sigma_{12}^2,\pi_1,\pi_2)  
=  
\prod_{g=1}^{2}  
\prod_{x_i\in C_g}  
\pi_g  
\frac{1}{(2\pi\sigma_{12}^2)^{d/2}}  
\exp  
\left(  
-\frac{  
\|x_i-\mu_g\|_2^2  
}{  
2\sigma_{12}^2  
}  
\right).  
\tag{17}$$

对式 $(17)$ 取对数，可得备择假设下的对数似然函数：

$$\ell_1(C_1,C_2)  
=  
\sum_{g=1}^{2}  
\sum_{x_i\in C_g}  
\log \pi_g  
-  
\frac{n_Cd}{2}\log(2\pi)  
-  
\frac{n_Cd}{2}\log\sigma_{12}^2  
-  
\frac{1}{2\sigma_{12}^2}  
\sum_{g=1}^{2}  
\sum_{x_i\in C_g}  
\|x_i-\mu_g\|_2^2.  
\tag{18}$$

由于：

$$\sum_{x_i\in C_g}\log\pi_g  
=  
n_g\log\pi_g,$$

式 $(18)$ 可进一步写为：

$$\ell_1(C_1,C_2)  
=  
n_1\log\pi_1+n_2\log\pi_2  
-  
\frac{n_Cd}{2}\log(2\pi)  
-  
\frac{n_Cd}{2}\log\sigma_{12}^2  
-  
\frac{1}{2\sigma_{12}^2}  
\sum_{g=1}^{2}  
\sum_{x_i\in C_g}  
\|x_i-\mu_g\|_2^2.  
\tag{19}$$

对于给定划分，两个子簇均值的极大似然估计分别为：

$$\hat{\mu}_1  
=  
\frac{1}{n_1}  
\sum_{x_i\in C_1}x_i,  
\qquad  
\hat{\mu}_2  
=  
\frac{1}{n_2}  
\sum_{x_i\in C_2}x_i.  
\tag{20}$$

两个子簇的簇内平方误差分别为：

$$W(C_1)  
=  
\sum_{x_i\in C_1}  
\left\|  
x_i-\hat{\mu}_1  
\right\|_2^2,$$ $$W(C_2)  
=  
\sum_{x_i\in C_2}  
\left\|  
x_i-\hat{\mu}_2  
\right\|_2^2.  
\tag{21}$$

共享方差的极大似然估计为：

$$\hat{\sigma}_{12}^2  
=  
\frac{  
W(C_1)+W(C_2)  
}{  
n_Cd  
}.  
\tag{22}$$

同样，为保证数值稳定性，引入 $\varepsilon>0$，得到：

$$\hat{\sigma}_{12}^2  
=  
\frac{  
W(C_1)+W(C_2)  
}{  
n_Cd  
}  
+  
\varepsilon.  
\tag{23}$$

混合比例的极大似然估计为：

$$\hat{\pi}_1=\frac{n_1}{n_C},  
\qquad  
\hat{\pi}_2=\frac{n_2}{n_C}.  
\tag{24}$$

将式 $(20)$、$(23)$、$(24)$ 代入式 $(19)$，得到双簇模型的极大对数似然：

$$\ell_1(C_1,C_2)  
=  
n_1\log\hat{\pi}_1  
+  
n_2\log\hat{\pi}_2  
-  
\frac{n_Cd}{2}  
\left[  
\log(2\pi\hat{\sigma}_{12}^2)+1  
\right].  
\tag{25}$$

式 $(25)$ 包含两部分含义。第一部分：

$$n_1\log\hat{\pi}_1+n_2\log\hat{\pi}_2$$

刻画两个子簇规模比例对似然的贡献。当划分极度不均衡时，该项会降低双簇模型的似然得分，从而抑制过小子簇。第二部分：

$$-\frac{n_Cd}{2}  
\left[  
\log(2\pi\hat{\sigma}_{12}^2)+1  
\right]$$

刻画双簇模型对节点内部样本分布的拟合程度。若二分后簇内平方误差明显下降，则 $\hat{\sigma}_{12}^2$ 变小，双簇模型的对数似然将增加。

上述似然结构对应于当前改进模型中使用的数学形式：单簇模型用节点整体簇内平方误差估计方差，双簇模型用两个子节点的簇内平方误差之和估计共享方差，并通过混合比例项约束划分均衡性。[![GitHub](data:image/png;base64,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)GitHub](https://raw.githubusercontent.com/hxz1003/3AMVC-/master/3AMVC-main/BIC_LR_HBNC.m)

---

### 3.3.2.3 似然比增益

对于一个候选划分 $C\rightarrow C_1\cup C_2$，定义单簇模型与双簇模型之间的似然比统计量：

$$\Lambda(C_1,C_2)  
=  
2\left[  
\ell_1(C_1,C_2)-\ell_0(C)  
\right].  
\tag{26}$$

若 $\Lambda(C_1,C_2)$ 较大，说明双簇模型相较于单簇模型显著提升了对当前节点数据的解释能力；反之，若 $\Lambda(C_1,C_2)$ 较小，则说明继续划分带来的拟合收益有限。

然而，单纯比较似然会偏向参数更多的双簇模型。因为双簇模型包含更多均值参数和混合比例参数，其拟合能力天然强于单簇模型。因此，本文进一步引入 BIC 复杂度惩罚。Schwarz 提出的 BIC 准则本质上是在极大似然的基础上加入模型维度惩罚，用于在不同参数维度的模型之间进行选择。[![](https://www.google.com/s2/favicons?domain=https://sites.stat.washington.edu&sz=128)华盛顿大学统计网站](https://sites.stat.washington.edu/courses/stat527/s13/readings/ann_stat1978.pdf?utm_source=chatgpt.com)

在单簇模型中，参数包括一个 $d$ 维均值向量和一个方差参数，因此参数量为：

$$p_0=d+1.  
\tag{27}$$

在双簇模型中，参数包括两个 $d$ 维均值向量、一个共享方差参数，以及一个独立混合比例参数，因此参数量为：

$$p_1=2d+2.  
\tag{28}$$

于是，双簇模型相对于单簇模型新增的参数量为：

$$\Delta p=p_1-p_0=d+1.  
\tag{29}$$

根据 BIC 模型选择思想，双簇模型只有在似然提升足以抵消复杂度惩罚时才应被接受。因此定义 BIC 正则化似然比得分：

$$S(C_1,C_2)  
=  
2\left[  
\ell_1(C_1,C_2)-\ell_0(C)  
\right]  
-  
\lambda_{\mathrm{BIC}}  
(d+1)\log n_C.  
\tag{30}$$

其中，$\lambda_{\mathrm{BIC}}>0$ 为 BIC 惩罚系数。当 $\lambda_{\mathrm{BIC}}=1$ 时，式 $(30)$ 对应标准 BIC 惩罚形式；当 $\lambda_{\mathrm{BIC}}>1$ 时，划分更加保守；当 $0<\lambda_{\mathrm{BIC}}<1$ 时，划分更容易被接受。

该判据与 X-means 中利用 BIC 判断局部簇是否继续分裂的思想一致：不预先固定最终簇数，而是通过信息准则决定当前局部结构是否需要进一步细分。[![](https://www.google.com/s2/favicons?domain=https://www.cs.cmu.edu&sz=128)CMU School of Computer Science+1](https://www.cs.cmu.edu/~dpelleg/download/xmeans.pdf?utm_source=chatgpt.com)

最终，如果存在候选划分满足：

$$S(C_1,C_2)>\tau_{\mathrm{split}},  
\tag{31}$$

则接受该划分；否则停止划分当前节点，并将当前节点中心作为锚点。这里，$\tau_{\mathrm{split}}$ 为划分接受阈值，通常可取 $0$。当 $\tau_{\mathrm{split}}=0$ 时，模型只有在双簇假设经过 BIC 惩罚后仍优于单簇假设时才接受划分。

需要说明的是，混合模型或分裂模型中的似然比检验常常涉及边界参数、未识别参数或非标准渐近分布，因此直接使用固定卡方阈值并不总是严格成立。Self 和 Liang 对非标准条件下最大似然估计与似然比统计量的渐近性质进行了系统讨论。因此，本文采用 BIC 正则化似然比作为局部模型选择准则，而不是直接依赖固定自由度的卡方显著性检验。[![](https://www.google.com/s2/favicons?domain=https://www.stat.cmu.edu&sz=128)卡内基梅隆大学统计与数据科学](https://www.stat.cmu.edu/~brian/763-2015/week06/papers/self-liang-1987.pdf?utm_source=chatgpt.com)

---

## 3.3.3 投影排序与候选切分点搜索

为了避免在高维空间中枚举所有可能的二分划分，本文首先在当前节点中构造一个局部分裂方向。设当前节点中得到两个粗分离中心：

$$c_1,c_2\in\mathbb{R}^{d}.$$

定义投影方向为：

$$u  
=  
\frac{c_1-c_2}  
{\|c_1-c_2\|_2+\varepsilon}.  
\tag{32}$$

然后，将当前节点中的每个样本投影到该方向上：

$$s_i=u^\top x_i,  
\qquad x_i\in C.  
\tag{33}$$

将投影值升序排列：

$$s_{(1)}\le s_{(2)}\le\cdots\le s_{(n_C)}.  
\tag{34}$$

由于投影方向刻画了当前节点中最主要的二分离趋势，因此只需要沿该一维排序序列扫描候选切分点。设每个子节点允许的最小样本数为 $n_{\min}$，则候选切分位置为：

$$k\in  
\{n_{\min},n_{\min}+1,\ldots,n_C-n_{\min}\}.  
\tag{35}$$

每个候选位置 $k$ 对应一个二分：

$$C_1(k)  
=  
\{x_{(1)},x_{(2)},\ldots,x_{(k)}\},$$ $$C_2(k)  
=  
\{x_{(k+1)},x_{(k+2)},\ldots,x_{(n_C)}\}.  
\tag{36}$$

对每个候选划分 $C_1(k),C_2(k)$，根据式 $(12)$、式 $(25)$ 和式 $(30)$ 计算 BIC 正则化似然比得分：

$$S_k  
=  
2\left[  
\ell_1(C_1(k),C_2(k))-\ell_0(C)  
\right]  
-  
\lambda_{\mathrm{BIC}}  
(d+1)\log n_C.  
\tag{37}$$

选择最优切分位置：

$$k^\ast  
=  
\arg\max_k S_k.  
\tag{38}$$

若：

$$S_{k^\ast}>\tau_{\mathrm{split}},  
\tag{39}$$

则接受划分：

$$C\rightarrow C_1(k^\ast)\cup C_2(k^\ast).  
\tag{40}$$

否则，当前节点停止划分。当前项目所表达的模型正是先构造局部分裂方向，再沿投影排序扫描候选二分点，并以 BIC 正则化似然比得分决定节点是否继续分裂。[![GitHub](data:image/png;base64,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)GitHub](https://raw.githubusercontent.com/hxz1003/3AMVC-/master/3AMVC-main/BIC_LR_HBNC.m)

需要强调的是，投影排序只用于限制候选切分点的搜索空间；似然估计中的簇内平方误差仍然基于原始 $d$ 维样本计算。因此，该过程并不是简单的一维聚类，而是利用一维投影提供高效候选划分，再在原特征空间中评价划分质量。

---

## 3.3.4 递归锚点生成

对每个视图 $v$，初始化叶节点集合：

$$\mathcal{L}^{(v)}=\{X^{(v)}\}.$$

对于任意当前节点 $C\in\mathcal{L}^{(v)}$，若其样本数不满足最小划分条件：

$$n_C<2n_{\min},  
\tag{41}$$

则不再划分该节点，并将其作为叶节点。

若 $n_C\ge 2n_{\min}$，则按照式 $(32)$–$(38)$ 搜索最优候选划分，并计算最优得分：

$$S^\ast(C)=\max_k S_k.  
\tag{42}$$

若满足：

$$S^\ast(C)>\tau_{\mathrm{split}},  
\tag{43}$$

则将当前节点替换为两个子节点：

$$C\rightarrow C_1(k^\ast)\cup C_2(k^\ast).  
\tag{44}$$

否则，当前节点停止划分。

当所有叶节点均不再满足划分条件时，递归过程终止。最终，第 $v$ 个视图得到叶节点集合：

$$\mathcal{L}^{(v)}  
=  
\left\{  
C_1^{(v)},C_2^{(v)},\ldots,C_{m_v}^{(v)}  
\right\}.  
\tag{45}$$

每个叶节点对应一个锚点，其定义为该叶节点内所有样本的均值：

$$\theta_j^{(v)}  
=  
\frac{1}{|C_j^{(v)}|}  
\sum_{x_i^{(v)}\in C_j^{(v)}}  
x_i^{(v)},  
\qquad  
j=1,2,\ldots,m_v.  
\tag{46}$$

于是得到第 $v$ 个视图的锚点矩阵：

$$\Theta^{(v)}  
=  
\left[  
\theta_1^{(v)},\theta_2^{(v)},\ldots,\theta_{m_v}^{(v)}  
\right]^\top  
\in\mathbb{R}^{m_v\times d_v}.  
\tag{47}$$

该递归机制保留了 3AMVC 中“逐层二分并自动停止”的锚点生成思想，但将原 HBNC 的启发式停止依据替换为具有统计解释的 BIC 正则化似然比准则。3AMVC 原文指出，HBNC 的目标是在不预先指定簇数的情况下自动获得每个视图的高质量锚点。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

# 3.4 视图质量评价与基准视图选择

在完成第 $v$ 个视图的递归锚点选择后，得到叶节点集合：

$$\mathcal{L}^{(v)}  
=  
\left\{  
C_1^{(v)},C_2^{(v)},\ldots,C_{m_v}^{(v)}  
\right\}.$$

根据每个叶节点的簇内平方误差，定义第 $v$ 个视图的锚点质量为：

$$q_v  
=  
\sum_{j=1}^{m_v}  
\sum_{x_i^{(v)}\in C_j^{(v)}}  
\left\|  
x_i^{(v)}-\theta_j^{(v)}  
\right\|_2^2.  
\tag{48}$$

其中，$q_v$ 越小，说明该视图中样本越接近其对应锚点，锚点对样本结构的代表性越强。3AMVC 原文也使用簇内距离来刻画锚点质量，并据此选择锚图质量最高的视图作为基准视图。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview+1](https://openreview.net/pdf?id=TKRqWQVawP)

因此，基准视图定义为：

$$b  
=  
\arg\min_{v}  
q_v.  
\tag{49}$$

该设计的含义是：跨视图对齐不应随机选择某个视图作为参考，而应将其他视图对齐到锚点质量最高的视图。3AMVC 论文明确指出，其方法根据锚图质量选择基准视图，并将其他视图锚图对齐到该基准视图。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

# 3.5 锚图学习

给定第 $v$ 个视图的锚点矩阵：

$$\Theta^{(v)}  
\in\mathbb{R}^{m_v\times d_v},$$

需要学习样本到锚点的关系矩阵：

$$Z^{(v)}  
\in\mathbb{R}^{n\times m_v}.$$

其中，第 $i$ 行 $z_i^{(v)}\in\mathbb{R}^{m_v}$ 表示样本 $x_i^{(v)}$ 与所有锚点之间的关联权重。为了使 $z_i^{(v)}$ 具有概率解释，要求：

$$z_i^{(v)}\ge 0,  
\qquad  
z_i^{(v)}\mathbf{1}_{m_v}=1.  
\tag{50}$$

因此，整个锚图矩阵满足：

$$Z^{(v)}\ge 0,  
\qquad  
Z^{(v)}\mathbf{1}_{m_v}=\mathbf{1}_{n}.  
\tag{51}$$

锚图学习可写为如下优化问题：

$$\min_{Z^{(v)},\Theta^{(v)}}  
\left\|  
X^{(v)}-Z^{(v)}\Theta^{(v)}  
\right\|_F^2  
+  
\beta  
\Omega(Z^{(v)}),  
\tag{52}$$ $$\text{s.t.}  
\quad  
Z^{(v)}\ge 0,  
\qquad  
Z^{(v)}\mathbf{1}_{m_v}=\mathbf{1}_{n}.  
\tag{53}$$

其中，第一项要求样本能够由锚点的加权组合进行重构，第二项 $\Omega(Z^{(v)})$ 是锚图正则项，$\beta>0$ 为正则化参数。3AMVC 论文中的多视图锚图学习目标同样采用样本—锚点重构形式，并要求锚图矩阵满足非负性与归一化约束。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

在该表示下，$Z_{ij}^{(v)}$ 表示第 $i$ 个样本与第 $j$ 个锚点之间的连接权重。由于：

$$\sum_{j=1}^{m_v}Z_{ij}^{(v)}=1,$$

因此每个样本在当前视图中被表示为所有锚点的凸组合。由此，锚图不仅描述样本与锚点之间的相似关系，也保留了样本在锚点空间中的结构分布。

---

# 3.6 跨视图锚图对齐

由于各视图独立执行自适应锚点选择，因此不同视图得到的锚点数量通常不同：

$$m_v\neq m_b.$$

于是，第 $v$ 个视图的锚图：

$$Z^{(v)}\in\mathbb{R}^{n\times m_v}$$

不能直接与基准视图锚图：

$$Z^{(b)}\in\mathbb{R}^{n\times m_b}$$

相加或融合。因此，需要学习一个将第 $v$ 个视图锚点空间映射到基准视图锚点空间的匹配矩阵：

$$P_v\in\{0,1\}^{m_v\times m_b}.$$

对齐后的第 $v$ 个视图锚图定义为：

$$\widetilde Z^{(v)}  
=  
Z^{(v)}P_v  
\in\mathbb{R}^{n\times m_b}.  
\tag{54}$$

对于基准视图，有：

$$\widetilde Z^{(b)}=Z^{(b)}.  
\tag{55}$$

为了同时考虑样本—锚点关系和锚点内部结构，定义第 $v$ 个视图的锚点结构图：

$$G^{(v)}  
=  
(Z^{(v)})^\top Z^{(v)}  
\in\mathbb{R}^{m_v\times m_v}.  
\tag{56}$$

基准视图的锚点结构图为：

$$G^{(b)}  
=  
(Z^{(b)})^\top Z^{(b)}  
\in\mathbb{R}^{m_b\times m_b}.  
\tag{57}$$

对齐后的第 $v$ 个视图锚点结构图为：

$$\widetilde G^{(v)}  
=  
P_v^\top G^{(v)}P_v  
\in\mathbb{R}^{m_b\times m_b}.  
\tag{58}$$

于是，非基准视图 $v\neq b$ 的对齐目标为：

$$\min_{P_v}  
\left\|  
Z^{(b)}-Z^{(v)}P_v  
\right\|_F^2  
+  
\lambda  
\left\|  
G^{(b)}-P_v^\top G^{(v)}P_v  
\right\|_F^2,  
\tag{59}$$ $$\text{s.t.}  
\quad  
P_v\mathbf{1}_{m_b}=\mathbf{1}_{m_v},  
\qquad  
P_v^\top\mathbf{1}_{m_v}=\mathbf{1}_{m_b},  
\qquad  
P_v\in\{0,1\}^{m_v\times m_b}.  
\tag{60}$$

其中，第一项对齐样本—锚点关系，第二项对齐锚点内部结构，$\lambda>0$ 用于控制结构一致性约束的重要性。3AMVC 论文中的跨视图对齐目标也由锚图关系项和锚点内部结构项组成，并指出匹配矩阵能够表达基准视图与其他视图之间的一对多或多对一锚点关系。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

该对齐过程的意义在于：不同视图的锚点虽然都来自同一批样本，但由于视图特征空间不同、锚点数量不同、局部划分结果不同，锚点索引之间并不天然对应。因此，需要通过 $P_v$ 将不同视图的锚点空间统一到基准视图锚点空间中。

---

# 3.7 等权锚图融合

完成跨视图锚图对齐后，所有视图的锚图均被映射到基准视图的锚点空间中：

$$\widetilde Z^{(v)}  
\in\mathbb{R}^{n\times m_b},  
\qquad  
v=1,2,\ldots,V.$$

其中：

$$\widetilde Z^{(b)}=Z^{(b)}.$$

按照 3AMVC 论文中的融合策略，本文采用等权方式融合所有对齐后的锚图：

$$Z_{\mathrm{aligned}}  
=  
\frac{1}{V}  
\left(  
Z^{(b)}  
+  
\sum_{\substack{v=1\\v\neq b}}^{V}  
Z^{(v)}P_v  
\right).  
\tag{61}$$

也即：

$$Z_{\mathrm{aligned}}  
=  
\frac{1}{V}  
\sum_{v=1}^{V}  
\widetilde Z^{(v)}.  
\tag{62}$$

式 $(61)$ 与 3AMVC 论文中的对齐锚图融合公式一致。论文在获得各非基准视图的匹配矩阵后，将基准视图锚图与其他视图的对齐锚图相加并除以视图数，从而得到最终融合锚图。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

等权融合的含义是：在完成对齐后，每个视图都向最终共识锚图贡献相同权重。由于前一阶段已经将所有视图映射到基准视图锚点空间中，因此式 $(61)$ 可以直接在统一维度下融合不同视图的样本—锚点关系。与质量加权或对齐残差加权不同，等权融合不再额外引入视图权重参数，从而保持与 3AMVC 原论文一致的融合形式。

---

# 3.8 谱嵌入与最终聚类

得到融合锚图：

$$Z_{\mathrm{aligned}}  
\in\mathbb{R}^{n\times m_b}$$

后，对其进行奇异值分解：

$$Z_{\mathrm{aligned}}  
=  
U\Sigma V^\top.  
\tag{63}$$

其中：

$$U\in\mathbb{R}^{n\times n},  
\qquad  
\Sigma\in\mathbb{R}^{n\times m_b},  
\qquad  
V\in\mathbb{R}^{m_b\times m_b}.$$

取前 $K$ 个左奇异向量：

$$U_K=  
[u_1,u_2,\ldots,u_K]  
\in\mathbb{R}^{n\times K}.  
\tag{64}$$

最终，对 $U_K$ 的行向量执行 $K$-means 聚类：

$$\mathcal{Y}  
=  
K\text{-means}(U_K).  
\tag{65}$$

3AMVC 论文指出，在得到融合锚图后，对其进行谱分解，并在左奇异向量上执行 $K$-means，即可得到最终聚类结果。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

从图嵌入角度看，$U_K$ 给出了样本在融合锚图诱导的低维谱空间中的表示。若两个样本在多个视图中都具有相似的锚点连接结构，则它们在 $U_K$ 中的表示也会更接近，从而更容易被划分到同一簇中。

---

# 3.9 完整目标函数视角

整体上，本文方法可以被理解为三个层次的联合建模。

第一层是单视图自适应锚点生成：

$$\Theta^{(v)}  
=  
\mathcal{A}_{\mathrm{BIC-LR}}  
(X^{(v)}),  
\qquad  
v=1,2,\ldots,V.  
\tag{66}$$

其中，$\mathcal{A}_{\mathrm{BIC-LR}}$ 表示由式 $(1)$–$(47)$ 定义的递归锚点选择算子。该算子不预设锚点数 $m_v$，而是通过 BIC 正则化似然比得分自动决定节点是否继续分裂。

第二层是单视图锚图学习：

$$\min_{\{Z^{(v)},\Theta^{(v)}\}_{v=1}^{V}}  
\sum_{v=1}^{V}  
\left[  
\left\|  
X^{(v)}-Z^{(v)}\Theta^{(v)}  
\right\|_F^2  
+  
\beta\Omega(Z^{(v)})  
\right],  
\tag{67}$$ $$\text{s.t.}  
\quad  
Z^{(v)}\ge 0,  
\qquad  
Z^{(v)}\mathbf{1}_{m_v}=\mathbf{1}_{n},  
\qquad  
v=1,2,\ldots,V.  
\tag{68}$$

该目标与 3AMVC 中锚图学习的基本形式一致，即通过样本—锚点重构误差和锚图约束学习每个视图的锚图结构。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

第三层是跨视图对齐与等权融合：

$$\min_{\{P_v\}_{v\neq b}}  
\sum_{\substack{v=1\\v\neq b}}^{V}  
\left[  
\left\|  
Z^{(b)}-Z^{(v)}P_v  
\right\|_F^2  
+  
\lambda  
\left\|  
G^{(b)}-P_v^\top G^{(v)}P_v  
\right\|_F^2  
\right],  
\tag{69}$$ $$Z_{\mathrm{aligned}}  
=  
\frac{1}{V}  
\left(  
Z^{(b)}  
+  
\sum_{\substack{v=1\\v\neq b}}^{V}  
Z^{(v)}P_v  
\right).  
\tag{70}$$

因此，本文方法的整体逻辑可以概括为：

$$\text{BIC 正则化似然比检验决定锚点数}  
\Rightarrow  
\text{簇内误差评价锚点质量}  
\Rightarrow  
\text{高质量视图作为对齐基准}  
\Rightarrow  
\text{不同视图锚图对齐到统一锚点空间}  
\Rightarrow  
\text{等权融合得到共识锚图}  
\Rightarrow  
\text{谱嵌入获得最终聚类结果}.$$

---

# 3.10 算法描述

**输入：** 多视图数据 $\{X^{(v)}\}_{v=1}^{V}$，聚类数 $K$，锚图正则参数 $\beta$，对齐参数 $\lambda$，BIC 惩罚参数 $\lambda_{\mathrm{BIC}}$，最小节点规模 $n_{\min}$，划分阈值 $\tau_{\mathrm{split}}$。

**输出：** 聚类标签 $\mathcal{Y}$。

**步骤如下。**

1. 对每个视图 $v=1,\ldots,V$，初始化叶节点集合：

$$\mathcal{L}^{(v)}=\{X^{(v)}\}.$$

2. 对每个当前节点 $C$，计算节点中心 $\mu_C$ 与簇内平方误差 $W(C)$。
3. 构造局部分裂方向 $u$，将节点内样本投影到该方向上，并根据投影值排序。
4. 沿排序序列枚举所有满足最小节点规模约束的候选切分位置。
5. 对每个候选划分，分别计算单簇模型对数似然 $\ell_0(C)$ 和双簇模型对数似然 $\ell_1(C_1,C_2)$。
6. 根据式 $(30)$ 计算 BIC 正则化似然比得分。
7. 若最大得分 $S^\ast(C)$ 满足：

$$S^\ast(C)>\tau_{\mathrm{split}},$$

则接受该节点划分；否则将当前节点作为叶节点。

8. 当所有叶节点均不再继续划分时，令每个叶节点中心作为锚点，得到各视图锚点集合 $\Theta^{(v)}$。
9. 根据式 $(48)$ 计算每个视图的锚点质量 $q_v$，并根据式 $(49)$ 选择基准视图 $b$。
10. 根据式 $(52)$–$(53)$ 学习每个视图的锚图 $Z^{(v)}$。
11. 对每个非基准视图，根据式 $(59)$–$(60)$ 学习匹配矩阵 $P_v$，并得到对齐锚图 $Z^{(v)}P_v$。
12. 根据式 $(61)$ 或式 $(62)$ 对所有对齐锚图进行等权融合，得到 $Z_{\mathrm{aligned}}$。
13. 对 $Z_{\mathrm{aligned}}$ 进行奇异值分解，取前 $K$ 个左奇异向量 $U_K$。
14. 对 $U_K$ 的行向量执行 $K$-means，得到最终聚类标签 $\mathcal{Y}$。

---

# 3.11 复杂度分析

对于第 $v$ 个视图的某个节点 $C$，设其样本数为 $n_C$，特征维度为 $d_v$。构造局部分裂方向的计算代价近似为：

$$O(I n_C d_v),  
\tag{71}$$

其中 $I$ 表示局部二中心更新的迭代次数。

投影与排序的代价为：

$$O(n_Cd_v+n_C\log n_C).  
\tag{72}$$

若利用前缀统计量扫描候选切分点，则所有候选划分的簇内平方误差与似然得分可以在近似线性时间内计算，其复杂度为：

$$O(n_Cd_v).  
\tag{73}$$

因此，单个节点的划分评价复杂度约为：

$$O(I n_Cd_v+n_C\log n_C+n_Cd_v).  
\tag{74}$$

若第 $v$ 个视图最终生成 $m_v$ 个锚点，并且递归划分树近似平衡，则该视图锚点选择阶段的复杂度可近似表示为：

$$O(I n d_v\log m_v+n\log n).  
\tag{75}$$

与构造完整 $n\times n$ 样本相似图相比，该过程仍然避免了二次规模的图构造。3AMVC 原文也指出，其主要计算与样本数 $n$ 近似线性相关，能够更好适应大规模数据场景。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

锚图学习阶段主要涉及样本—锚点重构，复杂度与 $n$、$m_v$、$d_v$ 相关。跨视图对齐阶段主要依赖锚点数 $m_v$ 和基准视图锚点数 $m_b$，而不是完整样本数的平方。最终奇异值分解作用于 $n\times m_b$ 的融合锚图，其中 $m_b\ll n$，因此仍保持锚图方法在大规模聚类中的计算优势。

---

# 3.12 方法讨论

本文方法相对于原始 3AMVC 的主要变化在于：原 HBNC 使用基于邻域距离与层次二分的方式自动生成锚点，而本文将局部节点是否继续划分的问题改写为单簇模型与双簇模型之间的统计模型选择问题。3AMVC 原文指出，HBNC 的目标是在不指定簇数的情况下自动选择高质量锚点；本文保留该目标，但将停止准则替换为 BIC 正则化似然比判据。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview+1](https://openreview.net/pdf?id=TKRqWQVawP)

该替换带来三个主要优点。

第一，锚点数量的生成具有更清晰的统计解释。若当前节点的双簇模型在扣除 BIC 复杂度惩罚后仍优于单簇模型，则说明该节点内部存在值得保留的局部分裂结构，应继续生成更细粒度锚点；反之，则说明当前节点已足够紧凑，可以将其中心作为锚点。

第二，BIC 惩罚避免了单纯最大化似然导致的过划分问题。由于双簇模型参数量更多，若不加入复杂度惩罚，模型会倾向于不断分裂节点。式 $(30)$ 中的 $(d+1)\log n_C$ 项正是对新增参数复杂度的惩罚。

第三，该改进仍然保持 3AMVC 的视图自适应性质。不同视图独立执行递归似然比划分，因此可以根据自身数据结构生成不同数量的锚点。随后，跨视图对齐模块将不同数量的锚点映射到基准视图锚点空间，最后按照 3AMVC 原论文中的等权融合公式得到最终共识锚图。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview](https://openreview.net/pdf?id=TKRqWQVawP)

---

# 参考文献对应关系

本文方法各部分主要对应如下文献来源。

1. **3AMVC 总体框架、HBNC 自动锚点选择、锚点质量评价、基准视图选择、跨视图锚图对齐、等权融合与谱聚类**：Automatic and Aligned Anchor Learning Strategy for Multi-View Clustering，ACM MM 2024。[![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview+2![](https://www.google.com/s2/favicons?domain=https://openreview.net&sz=128)OpenReview+2](https://openreview.net/pdf?id=TKRqWQVawP)
2. **BIC 模型选择准则**：Schwarz, G. “Estimating the Dimension of a Model,” Annals of Statistics, 1978。本文式 $(30)$ 中的复杂度惩罚项来自 BIC 模型选择思想。[![](https://www.google.com/s2/favicons?domain=https://sites.stat.washington.edu&sz=128)华盛顿大学统计网站](https://sites.stat.washington.edu/courses/stat527/s13/readings/ann_stat1978.pdf?utm_source=chatgpt.com)
3. **基于 BIC 的自动簇数估计思想**：X-means 通过 BIC 判断局部簇是否继续分裂，从而避免预先固定簇数；本文的局部节点分裂判定与其模型选择思想一致。[![](https://www.google.com/s2/favicons?domain=https://www.cs.cmu.edu&sz=128)CMU School of Computer Science+1](https://www.cs.cmu.edu/~dpelleg/download/xmeans.pdf?utm_source=chatgpt.com)
4. **似然比检验在非标准条件下的注意事项**：Self and Liang 对非标准条件下最大似然估计与似然比统计量的渐近性质进行了讨论，因此本文采用 BIC 正则化似然比作为局部划分准则，而不是直接使用固定卡方阈值。[![](https://www.google.com/s2/favicons?domain=https://www.stat.cmu.edu&sz=128)卡内基梅隆大学统计与数据科学](https://www.stat.cmu.edu/~brian/763-2015/week06/papers/self-liang-1987.pdf?utm_source=chatgpt.com)