#import "@preview/lovelace:0.2.0": *
// 使用伪粗体修复中文粗体不能正确显示的问题
#import "@preview/cuti:0.3.0": show-cn-fakebold

#import "fonts/font-def.typ": *
#import "pages/acknowledgement.typ": acknowledgement
#import "pages/chinese-outline.typ": chinese_outline
#import "pages/declaration.typ": declaration
#import "pages/zh-abstract-page.typ": zh_abstract_page
#import "pages/en-abstract-page.typ": en_abstract_page
#import "pages/references.typ": _set_references
// #import "pages/paper-cover.typ": paper_cover
#import "pages/paper-pages.typ": *

#import "utilities/three-line-table.typ": three_line_table
#import "utilities/indent-funs.typ": *
#import "utilities/bib-cite.typ": *
#import "utilities/set-heading.typ": _set_heading
#import "utilities/set-figure.typ": _set_figure
#import "utilities/set-numbering.typ": _set_numbering

#import "variable/mse-trans-variable.typ": *

#let project(
  anonymous: false, // 是否匿名化处理
  title: "",
  title_trans: "",
  abstract_zh: [],
  keywords_zh: (),
  school: "",
  author: "",
  id: "",
  mentor: "",
  class: "",
  date: (2025, 2, 12),
  body,
) = {
  /* 全局整体设置 */

  // 设置标题, 需要在图表前设置
  show: _mse_trans_set_heading
  // 图表公式的排版
  show: _mse_trans_set_figure
  // 图表公式的序号
  show: _set_numbering
  // 参考文献
  show: _set_references.with(csl_style: "hust-cse-ug.csl")
  // 修复缩进
  show: _fix_indent
  // 整体页面设置
  show: _set_paper_page_size
  // 修复中文粗体不能正确显示的问题
  show: show-cn-fakebold

  /* 封面与原创性声明 */

  // 封面
  mse_trans_paper_cover(cover_logo_path: "../assets/cs-hust.png", 
    anonymous, title, school, class, author, id, mentor, date
  )

  // 翻译封底
  mse_trans_declaration()

  // 进入下一部分
  pagebreak()
  counter(page).update(1)

  /* 目录与摘要 */

  // 整体页眉
  show: _mse_trans_set_paper_page_header.with(anonymous: anonymous)
  // 目录与摘要的页脚
  show: _set_paper_page_footer_pre
  // 整体段落与页面设置
  show: _mse_trans_set_paper_page_par

  /* 正文 */

  // 正文的页脚
  show: _set_paper_page_footer_main

  counter(page).update(1)

  align(center)[
  #text(size: 14pt, weight: "bold")[#title_trans]
  ]

  // 摘要
  mse_trans_abstract(abstract_zh, keywords: keywords_zh)
  
  pagebreak()

  body

  orgin_intro()
}

#show: project.with(
  anonymous: false,
  title: "Dae R. Jeong, Kyungtae Kim, Basavesh Shivakumar, Byoungyoung Lee, Insik Shin. Razzer: Finding Kernel Race Bugs through Fuzzing. IEEE S&P 2019",
  id: "U202112205",
  title_trans: "Razzer: 通过模糊测试发现内核竞态漏洞",
  author: "刘浩阳",
  school: "网络空间安全学院",
  class: "网安本硕博2101班",
  mentor: "慕冬亮",
  abstract_zh: [
    
  ],
  keywords_zh: ("关键词1", "关键词2", "关键词3"),
)

= 引言
数据竞争不利于底层系统的可靠性和安全性。特别是对内核
而言，数据竞赛是各种有害行为的根源。如果数据竞争引入循环
锁行为，内核就会因由此产生的死锁而反应迟钝。如果驻留在内
核中的安全断言出现，内核将自行重启，从而导致拒绝服务。特
别是从安全性的角度来看，如果数据竞争导致内核中的传统内存
损坏（如传统的缓冲区溢出、释放后使用等），则可能会变成关
键的安全攻击，从而允许特权升级攻击，正如在滥用先前已知数
据竞争的内核漏洞中观察到的那样，如CVE-2016-8655[26]、
CVE-2017-2636[28]和CVE-2017-17712[27]。

针对与数据竞争相关的这些问题，人们在避免、防止或检测
数据竞争方面进行了大量研究。然而，据我所知，每种技术都有
一定的局限性，这主要是由于数据竞争本质上源于内核的非确定
性行为。更确切地说，理解数据竞争不仅需要精确的控制流和数
据流信息，还需要精确的并发执行信息，而这些信息受到许多底层系统的外部因素的严重影响（比如调度，同步原语等）。

在本文中，我们提出了一种基于模糊测试的数据竞争检测器 Razzer。Razzer 的关键洞察是它能够将模糊测试引导至内核中的潜在数据竞争点。为了实现这一点，Razzer 采用了一种混合方法，结合了静态和动态分析，以放大两种技术的优势并弥补其劣势。首先，Razzer 进行静态分析以获得潜在的数据竞争点的上界估计。基于这些潜在数据竞争点的信息，Razzer 进行两阶段的动态模糊测试。第一阶段是单线程模糊测试，专注于找到一个单线程输入程序，该程序执行潜在的竞争点（不考虑程序是否确实触发了竞争）。第二阶段是多线程模糊测试。它构建了一个多线程程序，并利用一个专门定制的虚拟机在其执行过程中故意使其在潜在的数据竞争点处停滞。因此，Razzer 避免了任何外部因素使竞争行为变得确定，使其成为一种高效的针对数据竞争的模糊测试工具。

我们使用 LLVM Pass 实现了 Razzer 的静态分析，并进行了指针分析，通过修改 QEMU 和 KVM（针对 x86-64 架构）开发虚拟机。为此，我们开发了一个两阶段的模糊测试框架，用于模糊测试内核的系统调用接口，同时利用静态分析结果以及定制的虚拟机。一旦 Razzer 识别到数据竞争，它不仅会输出用于重现该竞争的输入程序，还会提供一份详细的报告，便于理解数据竞争的根本原因。

我们的评估表明，Razzer 真正是一款可以部署的竞态检测工具。我们在撰写本文时，将 Razzer 应用于 Linux 内核的最新版本（从 v4.16-rc3 到 v4.18-rc3），并发现了内核中的 30 个新竞态漏洞。我们已经报告了这些竞态漏洞；截至目前，16 个竞态漏洞已被确认，内核开发者已经提交了 14 个补丁。此外，13 个竞态漏洞已被合并到各种受影响的内核版本中，包括主线内核在内。

为了突出Razzer在发现数据竞争方面的有效性，我们进行了一项受限制的比较，与其他先进的工具进行了对比，特别是 Syzkaller （即由 Google 开发的内核模糊测试工具）和 SKI （一个学术研究原型，通过随机化线程交织分析内核中的数据竞争）。 总结这项比较研究，Razzer 在识别三种竞态条件方面显著优于两种工具。与 Syzkaller 相比，Razzer 发现竞态条件所需的时间要少得多，最多相差 85 倍（最少相差 23 倍）。与 SKI 相比，Razzer 在探索线程交织情况以发现竞态条件方面更为有效，最多相差 398 倍（最少相差 30 倍）。

此外，我们向内核开发者的报告经验表明，Razzer 的详细分析报告有助于开发者轻松修复报告的竞态条件。具体来说，由于 Razzer 指出了竞态条件的具体位置（即内核中的两条内存访问指令引发的竞态条件）以及竞态条件发生时的调用堆栈，开发者能够轻松确定竞态条件的根本原因并开发相应的补丁。作为极端例子，我们通过 LKML [4] 报告了新发现的竞态条件后，两位内核开发者分别在 20 分钟和 2 小时内为我们的两个报告的竞态条件开发了补丁。鉴于关于数据竞态条件的普遍知识，特别是确定根本原因的难度，我们认为我们的报告表现出了促进数据竞态条件低成本、易操作修复的强大潜力。

本文做出了如下贡献：
- *面向数据竞争的模糊测试器*：我们提出了一种新的模糊测试机制，专门用于检测内核中的竞态条件。它利用了静态和动态分析技术，将模糊测试集中在潜在的竞态点上。
- *健壮的实现*：我们基于各种工业级框架实现了 Razzer，从 KVM/QEMU 到 LLVM 不等。分析目标内核时无需手动修改。我们认为其实现是足够稳健的，因为它可以轻松支持最新的 Linux 内核而无需任何手动干预。
- *实际影响*：我们在 Linux 内核中运行了 Razzer，发现其中有 30 个竞态条件，其中 16 个竞态条件已经被相应的内核开发者确认并修复。我们将开源 Razzer，以便内核开发者和研究人员能够从中受益。

#indent()本文组织如下。第二节定义了问题范围并确定了 Razzer 的设计要求。第三节介绍了 Razzer 的设计细节，第四节描述了其实现。第五节展示了 Razzer 的各种评估结果。第六节讨论了相关工作，第八节进行总结。
= 模板使用注意

本模板参考自 2024 年机械学院本科生毕设参考文献译文本模板，基本使用方法与本科生毕设模板相同，主要使用注意如下：

- 翻译文本如果不需要摘要，可在模板函数内删除
- 参考文献原文可在导出 pdf 后手动通过 Acrobat 等软件将原文合并到末尾。
- 译文要求的内容可手动修改函数 `mse_trans_declaration`

= 占位章节
== XXXX

== YYYY


#pagebreak()

sldjflsdjflsdj
