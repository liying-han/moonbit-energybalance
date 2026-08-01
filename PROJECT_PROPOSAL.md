# moonbit-energybalance 项目申报书

## 项目概述

`moonbit-energybalance` 是一个面向过程工程与化工计算的 MoonBit 能量衡算库，目标是在 MoonBit 生态中补齐与物料衡算互补的焓流、热负荷、换热和公用工程估算能力。项目以可复用库为主，附带 CLI 示例和可检查文档，适合课程实验、流程模拟原型、工程工具二次开发以及 MoonBit 数值计算生态扩展。

## 选题依据

赛前已在 Mooncakes 以 `energy balance`、`enthalpy`、`heat exchanger`、`thermodynamics`、`utility`、`能量衡算`、`换热器` 等关键词检索，未发现功能高度重合的成熟 MoonBit 包。该方向不局限于单一设备，而是围绕稳态能量方程组织通用抽象，后续可自然扩展到反应热、湿空气、蒸汽表、设备网络和流程求解器。

## 核心功能

当前版本实现热容模型、相变潜热、焓基准、纯流股与混合流股、稳态能量衡算、换热器 LMTD/UA/NTU、加热器、冷却器、混合器、分流器、闪蒸罐、公用工程估算和常用物性目录。单位约定清晰：温度 K、热容 J/mol/K、焓 J/mol、流量 mol/s、热负荷 W。公共 API 通过多个小文件维护，便于审查和长期维护。

## 技术路线

库采用 MoonBit 原生类型表达相态、热容模型、流股、衡算项和设备结果；用显式焓基准避免隐含状态；用黑盒测试覆盖典型工程场景，包括冷却器、加热器、换热器和闪蒸罐。CI 参考 MoonBit 社区 workflow 模板，在 Linux、macOS、Windows 上执行格式检查、`moon check --deny-warn`、`moon test --deny-warn` 和 `moon info` 生成漂移检查。

## 开源与交付

仓库包含 README、Apache-2.0 License、CHANGELOG、SOURCE 来源说明、GitHub Actions 和可运行 CLI demo。开发过程保持公开提交记录，贡献者仅为仓库账号本人。提交后可同时推送 GitHub 与 GitLink，默认分支保持 `main`，便于赛事表单填写、审核和后续 Mooncakes 发布。

## 计划与扩展

8 月上旬完成 0.1.0 可验收版本；中旬补充更多单元操作示例和工程算例；后续计划增加湿空气焓、蒸汽表接口、反应热、设备网络求解、误差传播和与物料衡算库的接口适配。项目将以小版本迭代保持 API 稳定，并优先补齐文档示例和测试覆盖。
