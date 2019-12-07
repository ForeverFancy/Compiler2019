# 组员贡献

## 贡献详述

### 虞佳焕

1. 设计并完成 `syntax_fun_declaration`, `syntax_var_declaration` 和 `syntax_param` 的访问函数。
2. 根据 clang 生成的 IR 确定了数组的访问模式。
3. 贡献了测试数组访问的 testcase.

### 张博文

1. 编写了 `program`, `num`, `return_stmt`, `simple_expression`, `additive_expression`, `call` 模块；
2. 提供了选择排序测试用例对项目整体正确性进行测试；
3. 实验文档的主要撰写人。

### 彭定澜

1. 设计并完成了 `componud_stmt`, `selection_stmt`, `iteration_stmt`, `var`, `assign_expression`, `term` 的访问。
2. 解决了 `selection_stmt` 和 `iteration_stmt` 中可能产生的空 bb_end 问题。
3. debug 主力。

## 评定结果

|  名字  | 百分比 |
| :----: | :----: |
| 虞佳焕 |  25 %  |
| 张博文 | 37.5 % |
| 彭定澜 | 37.5 % |

<!-- 百分比相加应当等于100%

可以对特殊情况进行备注 -->
