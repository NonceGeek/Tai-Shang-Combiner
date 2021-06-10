# TaiShang

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## 基本资料

项目名称：太上 NFT 炼金炉（TaiShang NFT Furnace）

项目立项日期 (哪年哪月)：2021 年 4 月。

## 项目整体简介

项目简介，中文提交。包括：

- 项目背景/原由/要解决的问题 (如有其他附件，可放到 `docs` 目录内。中文提交)。

  太上 NFT 炼金炉是「基于权益的多链 NFT 平台」的重要组成部分，但其同时也是一个独立提供服务的基础设施。

  太上在不改变原有 NFT 合约的基础上，通过附加「存证合约」，赋予 NFT 组合、拆解、生命周期、权益绑定等能力，锻造 NFT +，创造无限创新玩法与想象空间。

  ![太上 NFT 炼金炉简述 (4)](https://tva1.sinaimg.cn/large/008i3skNgy1gqkikcm71lj31r20u0wjr.jpg)

- 项目 logo (如有)，这 logo 会印制在文宣，会场海报或贴子上。

  ![LoGo](https://tva1.sinaimg.cn/large/008i3skNly1gr1agx4l7lj30hs0b4web.jpg)

## 黑客松期间计划完成的事项

请团队在报名那一周 git clone 这个代码库并创建团队目录，在 readme 里列出黑客松期间内打算完成的代码功能点。并提交 PR 到本代码库。例子如下 (这只是一个 nft 项目的例子，请根据团队项目自身定义具体工作)：

- [ ] **区块链端**

**技术栈：**Solidity/WASM

**简述：**标准erc721合约 + 存证合约

- [ ] `evidence`

基于工厂设计模式，作为erc721+的存证合约。

- [ ] `erc721`

标准erc721合约

---

- [ ] **炼金炉端**

**技术栈：**Elixir-Phoniex

**简述：** NFT 熔炼核心，支持界面/接口两种熔炼方式。

- [ ] `Syncer`

支持多链的链上-本地同步器。

- [ ] `Combiner`

  混合器，负责 NFT 的输入、处理与输出。

- [ ] `Caller`

  将 NFT 的输出结果通知 NFT 发行方。

- [ ] `可视化界面`

  基于 Phoniex 的炼金炉可视化界面，支持可视化「熔炼」NFT。

- [ ] `接口中心`

  通过接口进行 NFT 的「熔炼」。

---

- [ ] **解析端**

**技术栈：** 多语言。

**简述：** 适配该应用/该链，将 NFT + 实体化，如解析为「屠龙宝刀」、「游戏称号」等等等等。

- [ ] `Interactor`

和链进行交互。

- [ ] `Parser`

  NFT+ 解析器，解析内容包括原生 URL 与 Gene。


## 黑客松期间所完成的事项 (7月5日初审前提交)

- 7月5日前，在本栏列出黑客松期间最终完成的功能点。
- 把相关代码放在 `src` 目录里，并在本栏列出在黑客松期间打完成的开发工作/功能点。我们将对这些目录/档案作重点技术评审。
- 可选：放一段不长于 **5 分钟** 的产品 DEMO 展示视频, 命名为 `团队目录/docs/demo.mp4`。

## 队员信息

| 参赛人员姓名 | Github地址     |
| ------------ | -------------- |
| 李骜华       | leeduckgo      |
| 刘峰         | lekko1988      |
| 黄杰         | Blockchain_Key |
| 肖越         | xiaoyue2019    |
| 王宁波       | hqwangningbo   |

