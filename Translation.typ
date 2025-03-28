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
  mse_trans_paper_cover(
    cover_logo_path: "../assets/cs-hust.png",
    anonymous,
    title,
    school,
    class,
    author,
    id,
    mentor,
    date,
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
  title: "Ziyang Li, Saikat Dutta, Mayur Naik. IRIS: LLM-Assisted Static Analysis for Detecting Security Vulnerabilities. ICLR 2025",
  id: "U202112205",
  title_trans: "用于检测安全漏洞的LLM辅助的静态分析",
  author: "刘浩阳",
  school: "网络空间安全学院",
  class: "网安本硕博2101班",
  mentor: "慕冬亮",
  abstract_zh: [
    软件容易出现安全漏洞。由于依赖于人工标记的规范，用于检测它们的程序分析工具在实践中效果有限。大型语言模型（或 LLMs）已经显示出令人印象深刻的代码生成能力，但它们无法对代码进行复杂的推理来检测此类漏洞，尤其是因为此任务需要整个存储库分析。我们提出了 IRIS，这是一种神经符号方法，它系统地与静态分析相结合LLMs，以执行整个存储库推理以进行安全漏洞检测。具体来说，IRIS 利用它来LLMs推断污染规格并执行上下文分析，从而减轻对人工规格和检查的需求。为了进行评估，我们策划了一个新的数据集 CWE-Bench-Java，其中包含实际 Java 项目中的 120 个手动验证的安全漏洞。最先进的静态分析工具 CodeQL 仅检测到其中的 27 个漏洞，而带有 GPT-4 的 IRIS 检测到 55 个（+28），并将 CodeQL 的平均错误发现率提高了 5 个百分点。此外，IRIS 还识别了 6 个现有工具无法发现的以前未知的漏洞。
  ],
  keywords_zh: ("Neuro-Symbolic", "Program Analysis", "Security Vulnerability", "LLM"),
)

= 引言
安全漏洞对软件应用程序及其用户的安全构成重大威胁。仅在 2023 年，就报告了超过 29,000 个 CVE，比 2022 年高出近 4000 个 #bib_cite(<cvedetails>)。尽管发现漏洞的技术取得了进步，但检测漏洞极具挑战性。一种很有前途的技术称为静态污点分析，广泛用于 GitHub CodeQL#bib_cite(<codeql>)、Facebook Infer #bib_cite(<fbinfer>)、Checker Framework#bib_cite(<checker>) 和 Snyk Code#bib_cite(<synkio>) 等流行工具中。然而，这些工具面临着一些挑战，极大地限制了它们在实践中的有效性和可及性。

#figure(
  image("translation_assets\banner-new-2.svg"),
  caption: "IRIS 神经符号系统概述。它检查给定的整个存储库中是否存在给定类型的漏洞 （CWE），并输出一组潜在的易受攻击路径并附有解释。",
) <img1>

*由于缺少第三方库 API 的污点规范而导致的漏报。*首先，静态污点分析主要依赖于第三方库 API 的规范，如 source、sink 或排错器。在实践中，开发人员和分析工程师必须根据他们的领域知识和 API 文档手动制定此类规范。这是一个费力且容易出错的过程，通常会导致缺少规范和对漏洞的分析不完整。此外，即使许多库可能存在此类规范，也需要定期更新这些规范，以捕获此类库的较新版本中的更改，并涵盖开发的新库。

*由于缺乏精确的上下文敏感和直观的推理而导致的误报。*其次，众所周知，静态分析通常精度低，即它可能会产生许多误报#bib_cite(<kang2022detecting>,<johnson2013don>)。这种不精确源于多个来源。例如， source 或 sink 规范可能是虚假的，或者分析可能过度近似代码中的分支或可能的输入。此外，即使规范正确，使用检测到的 source 或 sink 的上下文也可能不可利用。因此，开发人员可能需要对几个可能错误的安全警报进行分类，从而浪费大量时间和精力。

*先前数据驱动方法在改进静态污点分析方面的局限性。*已经提出了许多技术来解决静态污染分析的挑战。例如，#bib_cite(<livshits2009merlin>)提出了一种概率方法，MERLIN，用于自动挖掘污点规格。最近的工作 Seldon#bib_cite(<chibotaru2019scalable>) 通过将污点规格推理问题表述为线性优化任务，提高了这种方法的可扩展性。但是，此类方法依赖于分析第三方库的代码来提取规范，这成本高昂且难以扩展。研究人员还开发了统计和基于学习的技术来减少误报警报 #bib_cite(<jung2005taming>, <heckman2009model>, <ranking2014finding>)。然而，这种方法在实践中仍然效果有限#bib_cite(<kang2022detecting>)。

大型语言模型（或 LLMs） 在代码生成和摘要方面取得了令人印象深刻的进步。LLMs也被应用于与代码相关的任务，如程序修复 #bib_cite(<xia2023automated>)、代码转换 #bib_cite(<pan2024lost>)、测试生成#bib_cite(<lemieux2023codamosa>) 和静态分析 #bib_cite(<li2024enhancing>)。最近的研究 #bib_cite(<steenhoek2024comprehensive>, <khare2023understanding>) 评估LLMs了在方法级别检测漏洞的有效性，LLMs并表明无法对代码进行复杂的推理，特别是因为它取决于方法在项目中使用的上下文。另一方面，最近的基准测试，如 SWE-Bench #bib_cite(<jimenez2023swe>) 表明，LLMs它们在进行项目级推理方面也很差。因此，一个有趣的问题是是否可以LLMs与静态分析相结合来提高他们的推理能力。在这项工作中，我们在漏洞检测的背景下回答了这个问题，并做出了以下贡献：

*方法*：我们提出了 IRIS，这是一种用于漏洞检测的神经符号方法，它结合了静态分析和 LLMs. @fig:img1 显示了 IRIS 的概述。给定一个要分析给定漏洞类别（或 CWE）的项目，IRIS 适用于LLMs挖掘特定于 CWE 的污点规范。IRIS 使用 CodeQL（一种静态污点分析工具）增强了此类规范。我们的直觉是因为LLMs已经看到了这种库 API 的大量用法，他们对不同 CWE 的相关 API 有了解。此外，为了解决静态分析的不精确性问题，我们提出了一种上下文分析技术，该技术LLMs可以减少误报并最大限度地减少开发人员的分类工作。我们的主要见解是，对 Prompt 中的代码上下文和路径敏感信息进行编码会从 LLMs中引出更可靠的推理。最后，我们的神经符号方法可以LLMs进行更精确的整个存储库推理，并最大限度地减少使用静态分析工具所涉及的人力。

*数据*：我们策划了一个手动审查和可编译的 Java 项目数据集 CWE-Bench-Java，其中包含四个常见漏洞类别的 120 个漏洞（每个项目一个）。数据集中的项目很复杂，平均包含 300K 行代码，10 个项目包含超过 100 万行代码，使其成为漏洞检测的具有挑战性的基准。我们的代码和数据集位于补充材料中，并在发布时开源。

*结果*：我们使用 8 种不同的开源和闭源 LLMs来评估 CWE-Bench-Java 上的 IRIS。总体而言，IRIS 使用 GPT-4 获得了最佳结果，检测到了 55 个漏洞，比现有性能最好的静态分析器 CodeQL 多了 28 个（103.7%）。我们表明，这种增加并不是以误报为代价的，因为带有 GPT-4 的 IRIS 的平均错误发现率为 84.82%，比 CodeQL 低 5.21%。此外，当应用于 30 个 Java 项目的最新版本时，带有 GPT-4 的 IRIS 发现了 6 个以前未知的漏洞。

= 动机示例
我们说明了 IRIS 在检测 cron-utils（版本 9.1.5）中以前已知的代码注入 （CWE094） 漏洞的有效性，cron-utils（用于 Cron 数据作的 Java 库）。@fig:img2 显示了相关的代码片段。传递到 isValid 函数的用户控制字符串值将传输到 parse 函数，而无需清理。如果引发异常，该函数将使用 input 构造错误消息。但是，错误消息用于调用 javax.validator 中类 ConstraintValidatorContext 的 buildConstraintViolationWithTemplate 方法，该方法将消息字符串解释为 Java 表达式语言 （Java EL） 表达式。恶意用户可能会利用此漏洞，通过制作包含 shell 命令（如 Runtime.exec（'rm -rf /'））的字符串来删除服务器上的关键文件。


#figure(
  image("translation_assets/motivating-vul.svg"),
  caption: "在 cron-utils （CVE-202141269） 中发现的代码注入 （CWE-94） 漏洞示例，CodeQL 无法检测到该漏洞。我们对易受攻击路径的程序点进行了编号。",
) <img2>

检测此漏洞会带来一些挑战。首先，cron-utils 库由 13K SLOC（不包括空格和注释的代码行）组成，需要对其进行分析才能找到此漏洞。此过程需要跨多个内部方法和第三方 API 分析数据和控制流。其次，分析需要确定相关的源和汇。在这种情况下，公共 isValid 方法的 value 参数在调用时可能包含任意字符串，因此可能是恶意数据的来源。此外，像 buildConstraintViolationWithTemplate 这样的外部 API 可以执行任意 Java EL 表达式，因此应将它们视为容易受到代码注入攻击的接收器。最后，分析还需要识别任何阻止不可信数据流的排错程序。

现代静态分析工具（如 CodeQL）可以有效地跟踪复杂代码库中的污点数据流。但是，由于缺少规范，CodeQL 无法检测到此漏洞。CodeQL 包括 360 多个常用 Java 库模块中许多手动策划的源和接收器规范。但是，手动获取此类规格需要大量的人力来分析、指定和验证。此外，即使具有完美的规范，由于缺乏上下文推理，CodeQL 也经常会产生大量误报，从而增加开发人员对结果进行分类的负担。
相比之下，IRIS 采用不同的方法，通过使用 LLMs动态推断特定于项目和漏洞的规范。IRIS 中基于 LLM的组件可以正确识别不受信任的源和易受攻击的 sink。IRIS 通过这些规范增强了 CodeQL，并成功检测了存储库中检测到的源和接收器之间未清理的数据流路径。但是，增强的 CodeQL 会产生许多误报，这些误报很难使用逻辑规则消除。为了解决这一挑战，IRIS 将检测到的代码路径和周围的上下文编码为一个简单的提示符，并使用 an LLM 将其分类为真阳性或假阳性。具体来说，在静态分析报告的 8 条路径中，过滤掉了 5 个误报，留下图 2 中的路径作为最终警报之一。总体而言，我们观察到 IRIS 可以检测到许多类似 CodeQL 的静态分析工具无法检测到的此类漏洞，同时将误报降至最低。

= IRIS 框架
在高级别上，IRIS 将 Java 项目 $P$ 、要检测的漏洞类$C$和大型语言模型LLM作为输入。IRIS 静态分析项目$ P$，检查特定于 $C$的漏洞，并返回一组潜在的安全警报$A$。每个警报都附有一个从污点源到易受$C$语言攻击的污点接收器的唯一代码路径（即，该路径未经过净化）。

#figure(
  image("translation_assets/pipeline.svg"),
  caption: "IRIS 管道图示",
) <img3>

如@fig:img3 所示，IRIS 有四个主要阶段：首先，IRIS 构建给定的 Java 项目，并使用静态分析来提取所有候选 API，包括调用的外部 API 和内部函数参数。其次，IRIS 查询将这些 LLM API 标记为特定于给定漏洞类别$C$的源或接收器。第三，IRIS 将标记的源和接收器转换为可馈送到静态分析引擎（如 CodeQL）的规范，并运行特定于漏洞类别的污点分析查询来检测项目中该类别的漏洞。此步骤在项目中生成一组易受攻击的代码路径（或警报）。最后，IRIS 通过自动筛选误报来对生成的警报进行分类，并将其呈现给开发人员。

== 问题定义
我们形式化地定义了用于漏洞检测的静态污点分析问题。给定一个项目$P$，污点分析提取一个过程间数据流图$GG = (VV，EE)$，其中 $VV$ 是表示程序表达式和语句的节点集，$EE in VV x VV$是表示节点之间的数据或控制流边的边集。漏洞检测任务包含两组$V_("Source")^C subset.eq VV comma V_("Sink")^C subset.eq VV$，分别表示受污染数据可能源自的源节点和受污染数据到达时可能出现安全漏洞的 sink 节点。自然，不同的$C$类漏洞（或 CWE）具有不同的 source 和 sink 规范。此外，可能还有 sanitizer 规范、$V_("Sanitizer")^C in VV$，它们会阻止受污染数据的流动（例如转义字符串中的特殊字符）。

污点分析的目标是查找源和汇对 $（V_s in V_("Source")^C comma V_t in V_("Sink")^C ）$，以便从源到汇有一条未净化的路径。更加形式化地，$"Unsanitized_Paths"(V_s, V_t) = exists "Path"(V_s, V_t) s.t  forall V_n in "Path"(V_s, V_t), V_n in V_("Sanitizer")^C$。这里，$"Path"（V_s， V_t）$ 表示一个节点序列 $（V_1， V_2， . . . ， V_k）$，使得 $V_i∈ VV$ 并且 $forall i in 1 "to" k − 1 ： （v_i， v_(i+1)） in EE$。

污点分析中的两个主要挑战包括：1） 确定每个$C$类的相关污点规格，这些规格可以映射到任何项目$P$的 $V_("Source")^C 、V_("Sink")^C$，以及 2） 有效消除污点分析识别的$"Unsanitized_Paths"(V_s, V_t)$ 中的假阳性路径。在以下部分中，我们将讨论如何利用 LLMs来应对每个挑战。

== 候选 Source/Sink 提取
项目可能会使用各种规范可能未知的第三方 API，从而降低污点分析的有效性。此外，内部 API 可能会接受来自下游库的不受信任的输入。因此，我们的目标是自动推断此类 API 的规范。我们将规范$S^C$ 定义为一个 3 元组 $⟨T， F， R⟩$，其中 $T in {"ReturnValue"， "Argument，" "Parameter"， . . . }$ 是要在$GG$中匹配的节点类型，$F$是一个字符串的$N$元组，描述 API 的包、类、方法名称、签名和参数/参数位置（如果适用），$R in {"Source"， "Sink"， "Taint-Propagator"， "Sanitizer"}$ 是 API 的角色。例如，规范$ ⟨"Argument"， "(java.lang, Runtime, exec, (String[]), 0）"， "Sink"⟩$表示 Runtime 类的 exec 方法的第一个参数是漏洞类（OS 命令注入）的 sink。静态分析工具将这些规范映射到$GG$中的$V_("Source")^C$或$V_("Sink")^C$节点集。

为了识别污点规范$S_("source")^C$和$S_("sink")^C$，我们首先提取$S^("ext")$： 在给定 Java 项目中调用的外部库 API，这些 API 可能是污点源或汇的候选者。我们还提取了$S^("int")$内部库 API，这些 API 是公共的，可以由下游库调用。我们使用 CodeQL 提取此类候选项及其相应的元数据，例如方法名称、类型签名、封闭的包和类，甚至 JavaDoc 文档（如果适用）。

#figure(
  image("translation_assets/contextual-analysis-prompt.svg", scaling: auto),
  caption: "LLM数据流路径上下文分析的用户提示和响应。在用户提示中，我们用颜色标记填充提示模板的 CWE 和路径信息。为了更清晰地显示，我们修改了代码段并省略了系统提示符。",
) <img4>

== 使用LLM推断污点
我们开发了一种自动规范推理技术：$"LabelSpecs"（S^(\#)， "LLM，" C， R） = S_R^C$，其中$S^(\#)= S^("ext") union S^("int")$是源和接收器的候选规范。在这项工作中，我们不考虑排错程序规范，因为它们通常不会因我们考虑的漏洞类别而异。我们用来LLMs推断污点规格。具体而言，$S^("ext")$中的外部 API 被分类为源或接收器，而$S^("int")$中的内部 API 将其正式参数标识为源。在附录中，我们展示了用户从外部 API 和内部函数形参推断 source 和 sink 规格的提示。

由于要标记的 API 数量庞大，因此我们在单个提示中插入一批 API，并要求 API LLM 使用 JSON 格式的字符串进行响应。批量大小是一个可优化的超参数。我们采用 few-shot（通常为 3-shot）提示策略来标记外部 API，而 zero-shot 用于标记内部 API。特别是对于内部 API，我们还包括来自存储库自述文件和 JavaDoc 文档的信息（如果适用）。在实践中，我们发现这些额外的信息有助于LLM理解代码库的高级目的和用法，从而提高标记的准确性。由于篇幅限制，我们将完整的 prompt 模板和其他实现细节留在附录中。在这个阶段的最后，我们成功获取了$S_("source")^C$和$S_("sink")^C$，这些都将被下一阶段的静态分析引擎使用。

== 漏洞检测
一旦我们从 获得所有 source 和 sink 规格LLM，下一步就是将其与静态分析引擎相结合，以检测给定项目中的易受攻击路径，即$"Unsanitized_Paths"(V_s, V_t)$。在这项工作中，我们使用 CodeQL#bib_cite(<codeql-web>) 来完成此步骤。CodeQL 将程序表示为数据流图，并提供一种类似于 Datalog#bib_cite(<smaragdakis2010using>) 的查询语言来分析此类图。许多安全漏洞可以使用用 CodeQL 编写的查询进行建模，并且可以针对从此类程序中提取的数据流图执行。给定项目$P$的数据流图$GG^P$，CWE 特定的源和接收器规范，以及对给定漏洞类$C$的查询，CodeQL 在程序中返回一组未经清理的路径。形式化地$ "CodeQL"(GG^P, S_("source")^C, S_("sink")^C, "Query"^C) = {"Path"_1, ..., "Path"_k} $
CodeQL 本身包含针对每个漏洞类别的许多第三方 API 规范。然而，正如我们稍后在评估中所展示的那样，尽管有如此专业的查询和广泛的规范，但 CodeQL 无法检测到实际项目中的大多数漏洞。为了进行分析，我们为每个漏洞编写了一个专门的 CodeQL 查询，该查询使用我们挖掘的规范，而不是 CodeQL 提供的规范。我们对 Path Traversal 漏洞 （CWE 22） 的查询如附录中的清单 3 所示。我们为评估的每个 CWE 开发类似的查询。

== 通过上下文分析对警报进行分类
推断污点规格只能解决部分挑战。我们观察到，虽然有助于发现许多新的 API 规范，但LLMs有时它们会检测到与所考虑的漏洞类别无关的规范，从而导致预测的源或接收器过多，从而导致许多虚假警报。就上下文而言，即使是几百个污点规范有时也可能产生数千个未净化的路径（V、V），开发人员需要对其进行分类。为了减轻开发人员的负担，我们还开发了一种LLM基于 的过滤方法，$"FilterPath"（"Path"， GG， "LLM"， C） = "True"|"False"$，通过利用基于上下文和自然语言的信息，将$GG$中检测到的易受攻击路径 （Path）分类为真阳性或假阳性。

@fig:img4 显示了上下文分析的示例提示。该提示包括路径上节点的 CWE 信息和代码片段，重点是源和接收器。具体来说，我们在确切的 source 和 sink 位置以及封闭函数和类周围包括 ±5 行。source 和 sink 的确切行标有注释。对于中间步骤，我们包括文件名和代码行。当路径太长时，我们只保留节点的子集以限制提示的大小。因此，我们提供了要全面分析潜在漏洞的完整上下文。

我们希望 以 LLM JSON 格式响应，并提供最终裁决以及对裁决的解释。JSON 格式会提示 在LLM做出最终裁决之前生成解释，因为已知在推理过程之后提出判决会产生更好的结果。此外，如果判定为 false，则我们要求 指示 LLM source 或 sink 是误报，这有助于修剪其他路径，从而节省对LLM的调用次数。

== 评估指标
我们使用三个关键指标评估 IRIS 及其基线的性能：检测到的漏洞数量 （\#Detected）、平均错误发现率 （AvgFDR） 和平均 F1 （AvgF1）。为了进行评估，我们假设我们有一个数据集$D = {P_1， . . . ， P_n}$，其中每个$P_i$都是一个 Java 项目，并且已知包含至少一个漏洞。项目$P$的标签以一组关键程序点 $V_("Vul")^P= {V_1， . . . . ， V_n}$的形式提供，易受攻击的路径应该通过这些点，由$"Path" sect V_("Vul")^P eq.not nothing$表示。在实践中，这些通常是可以从每个漏洞报告中收集的修补方法。如果检测到的至少一个易受攻击的路径通过给定漏洞的固定位置，则我们认为检测到的漏洞。设$"Paths"^P$前一阶段每个项目 P 检测到的路径集。指标的形式化定义如下：

#figure(image("translation_assets/formula.png"))

具体来说，AvgFDR越低越好，因为它表示较低的误报率。我们注意到如果检测工具未检索到$"Paths"（|"Paths"^P|= 0）$，$"Prec"(P)$有时候会因为divide-by-zero而未定义。因此，要使 AvgFDR 有意义，我们只考虑检测工具产生至少一个阳性结果$（|"Paths"^P| gt 0）$的项目。另一方面，AvgF1 不会遇到这个问题，因为当没有返回正结果时$"Rec"（P ） eq 0$，使整个 F1 项为 0，而不管 Prec（P ） 的未定义性如何。

= CWE-Bench-Java：Java 中的安全漏洞数据集
为了评估我们的方法，我们需要一个 Java 项目的易受攻击版本的数据集，该数据集具有几个重要特征：1） 每个基准测试都应该有相关的*漏洞元数据*，例如 CWE ID、CVE ID、修复提交和易受攻击的项目版本，2） 数据集中的每个项目都必须是*可编译的*，这是静态分析和数据流图提取的关键要求， 3） 项目必须是*真实的*，与综合基准相比，它们通常更复杂，因此难以分析， 4） 最后，必须*验证*项目中每个漏洞及其位置（例如方法），以便这些信息可用于对漏洞检测工具的稳健评估。遗憾的是，没有现有的数据集满足所有这些要求。 显示了我们的数据集（我们接下来将讨论）与之前的漏洞数据集的比较。

#figure(
  image("translation_assets/dataset-collection.svg"),
  caption: "管理 CWE-Bench-Java 和数据集统计信息的步骤",
) <img5>

为了满足这些要求，我们整理了自己的漏洞数据集。在本文中，我们只关注 Java 库中的漏洞，这些漏洞可通过广泛使用的 Maven 包管理器获得。我们选择 Java 是因为 Java 常用于开发服务器端、Android 和 Web 应用程序，这些应用程序容易存在安全风险。此外，由于 Java 的历史悠久，许多 Java 项目中有许多现有的 CVE 可供分析。我们最初使用 GitHub Advisory#bib_cite(<ghadvdb>, <ghadvgithub>) 数据库来获取此类漏洞，并使用来自多个来源的交叉验证信息进一步过滤它，包括手动验证。@fig:img5 说明了管理 CWE-Bench-Java 的完整步骤集。

如统计数据（@fig:img5）所示，这些项目的庞大规模使得任何静态分析工具或基于 ML 的工具都难以分析。CWE-Bench-Java 中的每个项目都附带 GitHub 信息、易受攻击和修复版本、CVE 元数据、自动获取和构建的脚本以及涉及漏洞的程序位置集。

= 评估
我们对 IRIS 进行了广泛的实验评估，并展示了它在 CWE-Bench-Java 中检测真实 Java 存储库中的漏洞方面的实际有效性。由于篇幅限制，我们在附录中提供了其他结果和分析。我们回答以下研究问题：

- *问题1*：IRIS 可以检测到多少个以前已知的漏洞？
- *问题2*：IRIS 是否检测到新的、以前未知的漏洞？
- *问题3*：IRIS 推断的 source/sink 规格有多好？
- *问题4*：IRIS 的各个组件效果如何？

== 实验设置
我们从 OpenAI 中选择了两个闭源LLMs：GPT 4 （gpt-4-0125-preview） 和 GPT 3.5 （gpt-3.5-turbo-0125） 进行评估。我们还通过 huggingface API 选择了三个开源LLMs的指令调整版本：Llama 3 8B 和 70B 以及 DeepSeekCoder 7B。对于 CodeQL 基准，我们使用版本 2.15.3 及其专为每个 CWE 设计的内置安全查询。包括的其他基线包括 Facebook Infer#bib_cite(<fbinfer>)、SpotBugs#bib_cite(<luigi2020spotbugs>) 和 Snyk #bib_cite(<synkio>)。我们在附录中进一步扩展了其他实验设置。

== 问题1：IRIS 在检测现有漏洞方面的有效性
IRIS 的有效性。@fig:tb1 中的结果突出了 IRIS 与 CodeQL 相比的卓越性能。具体来说，IRIS 与 GPT-4 配对时，可识别 55 个漏洞，比 CodeQL 多 28 个。虽然 GPT-4 显示出最高的功效，但像 DeepSeekCoder 7B 这样更小、更专业的LLMs仍然检测到 52 个漏洞，这表明我们的方法可以有效地利用较小规模的模型，增强可访问性。值得注意的是，检测到的漏洞的增加并不会影响精度，与 CodeQL 相比，IRIS 使用 GPT-4 的平均错误发现率 （FDR） 较低，这证明了这一点。此外，IRIS 将平均 F1 提高了 0.1，反映了精度和召回率之间的更好平衡。我们注意到，报告的平均 FDR 是一个上限，因为我们的指标可能会忽略存储库中的其他真实漏洞。为了进一步评估检测准确性，我们使用 GPT-4 对 IRIS 报告的 50 个警报进行随机采样，发现 50 个警报中有 27 个表现出潜在的攻击面，从而得出更精细的估计错误发现率为 46%。

#figure(
  image("translation_assets/table1.png"),
  caption: "CodeQL 与 IRIS 在检测率 （↑）、平均 FDR （↓） 和平均 F1 （↑） 方面的总体性能比较。我们展示了不同的 LLMs IRIS 结果，包括 OpenAI GPT-4 和 GPT-3.5、Llama-3 （L3） 8B 和 70B 以及 DeepSeekCoder （DSC） 7B",
) <tb1>

@fig:tb2 显示了检测到的漏洞的详细分类，将 IRIS 与各种基线进行了比较。除了使用 Llama-3 8B 的 IRIS 在检测 CWE-22 漏洞方面表现不佳外，IRIS 的性能始终优于所有其他基线。值得注意的是，CWE-78（系统命令注入）对所有的LLM都很具有挑战性。我们的手动调查显示，CWE-78 中的漏洞模式非常复杂，通常涉及通过小工具链#bib_cite(<cao2023gadget>) 注入作系统命令或外部副作用，例如文件写入，这些副作用很难使用静态分析进行跟踪。这凸显了静态分析的固有局限性，而不是动态方法，这是我们留给未来工作的领域。

== 问题2：IRIS 以前未知的漏洞
我们将 IRIS 与 GPT-4 应用于 30 个 Java 项目的最新版本。在 IRIS 提出至少一项警报的 16 个被检查项目中，我们发现了 6 个潜在漏洞，其中 4 个已向开发商报告，有待确认。这些报告的漏洞包括 3 个路径注入实例 （CWE-22） 和 1 个跨站点脚本案例 （CWE-94）。为了确保这些漏洞确实由于 IRIS 与 LLMs的集成而被发现，我们验证了它们无法仅由 CodeQL 检测到。附录中提供了详细的发现，但我们在 @fig:img8 中重点介绍了一个这样的漏洞。由于缺少源规范，CodeQL 无法检测到此问题，而 GPT-4 成功地将 API 端点 restoreFromCheckpoint 标记为潜在的攻击入口点。

== 问题3：LLM推断的污点规格的质量
LLM-inferred 污点规范是 IRIS 有效性的基础。为了评估这些规格的质量，我们进行了两项实验。首先，我们使用 CodeQL 的污点规格作为基准来估计由（@fig:img6）推断的LLMs源和接收器规格的召回率。但是，由于 CodeQL 提供的规范集有限，我们还需要评估其已知覆盖范围之外的推断规范的质量。为此，我们手动分析了 960 个随机选择的 source 和 sink 标签样本LLM（每个 CWE 和 LLM组合 30 个），并估计了规格的整体精度（@fig:img7）。

LLM-inferred sink 可以替换 CodeQL sink。总体而言，在根据 CodeQL 的 sink 规范进行测试时表现出LLMs高召回率（@fig:img6），其中 GPT-4 得分最高 （87.11%）。虽然源规范的召回率通常较低，但我们发现 CodeQL 往往会过度近似其源规范，以补偿低检测率。另一方面，GPT-4 在人工评估中实现了高精度（超过 70%）（@fig:img7），与之前@fig:tb1 中报告的较低错误发现率一致。对于 other LLMs，高召回率但较低精度的组合表明有过度近似 sink 规格的趋势。

#figure(
  image("translation_assets/table2.png"),
  caption: "按基准和 IRIS 检测到的漏洞数量 （#Detected） 的每 CWE 统计数据。比较的基准是 CodeQL （QL）、Facebook Infer （Infer）、Spotbugs （SB） 和 Snyk。括号中的值显示 IRIS 与 CodeQL 的检测差异。",
) <tb2>

#grid(
  rows: 1,
  columns: 2,
  [
    #figure(
      image("translation_assets/spec-codeql-recall.png", width: 6cm),
      caption: "根据 CodeQL 的污点规范召回 LLM-inferred 污点规范",
    ) <img6>],
  [
    #figure(
      image("translation_assets/spec-manual-precision.png", width: 6cm),
      caption: "随机采样标签上推断的规格的估计精度LLM"
    ) <img7>,
  ],
)


// #figure(image("translation_assets/spec-manual-precision.png"), caption: "随机采样标签上推断的规格的估计精度LLM") <img7>

#figure(
  image("translation_assets/new-bug-example.svg"),
  caption: "在 alluxio 2.9.4 中发现的以前未知的漏洞。为了便于演示，代码段略有修改",
) <img8>

过度近似的规格可能使 IRIS 受益。尽管 GPT-4 LLMs 以外的精度较低，但过度近似实际上可以帮助解决 CodeQL 的核心限制，即其受限制的污点规范集。通过过度近似，LLMs扩大了污点分析的覆盖范围，为 CodeQL 的有限范围提供了部分解决方案。这种不精确性的影响可以通过上下文分析来减轻，正如我们接下来在消融研究中展示的那样。

== 问题4：消融研究
*LLM 推理的源和汇都是必需的*。@fig:tb3 显示了仅使用 LLM in IRIS 中的 source 或 sink 规范时的其他结果。对于本实验，我们只使用 GPT-4 的结果进行比较。每行显示每个 CWE 检测到的漏洞数量。我们观察到，省略 GPT-4 推断的 source 或 sink 规格会导致整体召回率急剧减少。

*上下文分析的性能增益取决于 LLM的推理能力*。如@fig:img9 所示，上下文分析对于提高精度和 F1 分数是非常必要的。然而，在上下文分析后，只有 GPT-4、GPT-3.5 和 Llama-3 70B 看到了积极影响，而较小的模型则看到了负面影响。当LLM拥有良好的推理能力时，上下文分析的假阳性减少是最有效的。事实上，较小的模型比较大的模型更有可能用“易受攻击”来回应。

#grid(
  columns: 2,
  rows: 1,
  column-gutter: 0.8cm,
  [
    #figure(
      image("translation_assets/table3.png"),
      caption: "使用 #Detected 指标评估 LLM 推断的源和接收器规范（CodeQL (QL) 与 GPT-4）的消融。当用 CodeQL 规范替换源或接收器时，我们发现检测到的漏洞明显减少。",
    ) <tb3>
  ],
  [
    #figure(
      image("translation_assets/ablation-contextual-analysis.png"),
      caption: "上下文分析后平均精度和平均 F1 的改进",
    ) <img9>
  ],
)

= 相关工作
基于 ML 的漏洞检测方法。许多先前的技术都结合了深度学习来检测漏洞。这包括使用基于图神经网络 （GNN） 的代码表示的技术，例如 Devign#bib_cite(<Zhou2019DevignEV>)、Reveal#bib_cite(<Chakraborty2020DeepLB>)、LineVD#bib_cite(<Hin2022LineVDSV>) 和 IVDetect #bib_cite(<Li2021VulnerabilityDW>);基于 LSTM 的模型，用于表示程序切片和数据依赖关系，例如 VulDeePecker [32] 和 SySeVR#bib_cite(<Li2018SySeVRAF>);以及基于 Transformer 的模型的微调，例如 LineVul#bib_cite(<fu2022linevul>)、DeepDFA#bib_cite(<steenhoek2023dataflow>) 和 ContraFlow#bib_cite(<Cheng2022PathsensitiveCE>)。这些方法侧重于方法级漏洞检测，并且仅提供将方法分类为易受攻击或不易受攻击的二进制标签。相比之下，IRIS 执行整个项目分析，并提供从源到接收器的不同代码路径，并且可以针对检测不同的 CWE 进行定制。最近，多项研究表明，这些LLMs漏洞在检测实际代码中的漏洞方面是无效的#bib_cite(<steenhoek2024comprehensive>, <ding2024vulnerability>, <khare2023understanding>)。虽然这些研究只关注方法级的漏洞检测，但它加强了我们的动力，即检测漏洞需要整个项目的推理，而LLMs目前无法单独完成。

静态分析工具。除了 CodeQL#bib_cite(<codeql>)之外，其他静态分析工具，如 CppCheck #bib_cite(<cppcheck>)、Semgrep #bib_cite(<semgrep>)、FlawFinder #bib_cite(<flawfinder>)、Infer #bib_cite(<fbinfer>) 和 CodeChecker #bib_cite(<codechecker>) 也包括漏洞检测分析。但是，这些工具不如 CodeQL #bib_cite(<li2023comparison>, <lipp2022empirical>) 功能丰富和有效。最近，Snyk#bib_cite(<synkio>) 和 SonarQube#bib_cite(<sonarqube>) 等专有工具也越来越受欢迎。但是，与 CodeQL 一样，这些工具具有相同的基本限制，即缺少规范和误报，IRIS 对此进行了改进。我们的技术可能会使所有这些工具受益。

基于LLM的软件工程方法。研究人员越来越多地与程序推理工具相结合LLMs，以完成具有挑战性的任务，例如模糊测试 #bib_cite(<lemieux2023codamosa>, <xia2024fuzz4all>)、程序修复 #bib_cite(<xia2023automated>, <joshi2023repair>, <xia2022less>) 和故障定位 #bib_cite(<yang2023large>)。虽然我们的方向与 #bib_cite(<li2024enhancing>) 相似，但据我们所知，我们的工作是最早与静态分析相结合LLMs，通过整个项目分析来检测应用程序级安全漏洞的工作之一。最近，LLM基于 AutoCodeRover #bib_cite(<zhang2024autocoderover>) 和 SWE-Agent #bib_cite(<sweagent>) 的代理也在突破整个项目修复的界限。因此，在未来，我们计划探索 IRIS 中更丰富的工具组合，以进一步提高漏洞检测的性能。

= 结论与局限性
我们介绍了 IRIS，这是一种新颖的神经符号方法，与静态分析相结合LLMs进行漏洞检测。我们管理了一个数据集 CWE-Bench-Java，其中包含实际项目中四个类别的 120 个安全漏洞。我们的结果表明，系统地结合LLMs静态分析在检测到的错误和减轻开发人员的负担方面，比单独的传统静态分析有了显著的改进。

*局限性*。IRIS 仍有许多漏洞无法检测到。未来的方法可能会探索这两个工具的更紧密集成，以提高性能。此外，IRIS 会多次调用LLMs规范推理和过滤误报，从而增加了潜在的分析成本。尽管我们在 Java 上的结果表现良好，但尚不清楚 IRIS 在其他语言上的表现如何。此外，IRIS 生成的报告与开发人员希望看到的报告之间仍然存在差距。我们计划在未来的工作中进一步探讨这一点。

#pagebreak()
#bibliography("translation_ref.bib")
