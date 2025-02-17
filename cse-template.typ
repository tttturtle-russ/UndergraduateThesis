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
#import "pages/paper-cover.typ": paper_cover
#import "pages/paper-pages.typ": *

#import "utilities/three-line-table.typ": three_line_table
#import "utilities/indent-funs.typ": *
#import "utilities/bib-cite.typ": *
#import "utilities/set-heading.typ": _set_heading
#import "utilities/set-figure.typ": _set_figure
#import "utilities/set-numbering.typ": _set_numbering

#let project(
  anonymous: false, // 是否匿名化处理
  title: "",
  abstract_zh: [],
  abstract_en: [],
  keywords_zh: (),
  keywords_en: (),
  school: "",
  author: "",
  id: "",
  mentor: "",
  class: "",
  date: (2025, 2, 17),
  body,
) = {
  /* 全局整体设置 */

  // 设置标题, 需要在图表前设置
  show: _set_heading
  // 图表公式的排版
  show: _set_figure
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
  paper_cover(cover_logo_path: "../assets/cse-hust.png", 
    anonymous, title, school, class, author, id, mentor, date
  )

  // 原创性声明
  declaration(anonymous: anonymous)

  // 原创性声明与摘要间的空页
  // pagebreak()
  // counter(page).update(0)

  // 进入下一部分
  pagebreak()
  counter(page).update(1)

  /* 目录与摘要 */

  // 整体页眉
  show: _set_paper_page_header.with(anonymous: anonymous)
  // 目录与摘要的页脚
  show: _set_paper_page_footer_pre
  // 整体段落与页面设置
  show: _set_paper_page_par

  // 摘要
  zh_abstract_page(abstract_zh, keywords: keywords_zh)

  pagebreak()

  // abstract
  en_abstract_page(abstract_en, keywords: keywords_en)

  pagebreak()

  // 目录
  chinese_outline()

  /* 正文 */

  // 正文的页脚
  show: _set_paper_page_footer_main

  counter(page).update(1)

  body
}

#show: project.with(
  anonymous: false,
  title: "基于",
  id: "U202112205",
  author: "刘浩阳",
  school: "网络空间安全学院",
  class: "网安本硕博2101班",
  mentor: "慕冬亮",
  abstract_en: [],
  abstract_zh: [],
)

= 绪论
这是绪论

== 这是第二小节

=== 这是第三小节

== 这是第三小节

