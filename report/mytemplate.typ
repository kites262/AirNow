#let IMAGE_BOX_MAX_WIDTH = 120pt
#let IMAGE_BOX_MAX_HEIGHT = 50pt

#let full-page-chapter = state("full-page-chapter", false)

#let project(
  title: "",
  subtitle: none,
  header: none,
  school-logo: none,
  company-logo: none,
  authors: (),
  mentors: (),
  branch: none,
  academic-year: none,
  footer-text: "ENSIAS",
  features: (),
  heading-numbering: "1.1",
  accent-color: rgb("#ff4136"),
  font: ("New Computer Modern", "Noto Serif CJK SC"),
  // 目录开关
  show-toc: true,
  show-figures-table: false,
  show-tables-table: false,
  body,
) = {
  // 文档元信息
  set document(
    author: authors,
    title: title,
  )

  // 页眉：显示当前一级标题
  if features.contains("header-chapter-name") {
    set page(header: context {
      let headings = query(heading.where(level: 1).before(here()))
      let current-page-headings = query(heading.where(level: 1).after(here())).filter(h => (
        h.location().page() == here().page()
      ))

      if headings == () {
        []
      } else {
        let current-chapter = headings.last()

        if current-chapter.level == 1 and current-chapter.numbering != none {
          let in-page-heading = if current-page-headings.len() > 0 {
            current-page-headings.first()
          } else {
            none
          }

          if in-page-heading == none or in-page-heading.level != 1 or in-page-heading.numbering == none {
            let count = counter(heading).at(current-chapter.location()).at(0)

            align(end)[
              #text(accent-color, weight: "bold")[
                第 #count 章：
              ]
              #current-chapter.body
              #line(length: 100%)
            ]
          }
        }
      }
    })
  }

  // 页脚
  set page(
    numbering: "1",
    number-align: center,
    footer: context {
      let page-number = counter(page).get().at(0)

      if page-number > 1 and not full-page-chapter.get() {
        line(length: 100%, stroke: 0.5pt)
        v(-2pt)
        text(size: 12pt, weight: "regular")[
          #footer-text
          #h(1fr)
          #page-number
          #h(1fr)
          #academic-year
        ]
      }

      full-page-chapter.update(false)
    },
  )

  // 全局文本设置
  set text(
    font: font,
    size: 13pt,
  )

  set heading(numbering: heading-numbering)

  // 标题样式
  show heading: it => {
    set par(first-line-indent: 0pt, justify: false)

    if it.level == 1 and it.numbering != none {
      if features.contains("full-page-chapter-title") {
        pagebreak()
        full-page-chapter.update(true)

        v(1fr)
        [
          #text(weight: "regular", size: 30pt)[
            第 #counter(heading).display() 章
          ]
          #linebreak()
          #text(weight: "bold", size: 36pt)[
            #it.body
          ]
          #line(
            start: (0%, -1%),
            end: (15%, -1%),
            stroke: 2pt + accent-color,
          )
        ]
        v(1fr)

        pagebreak()
      } else {
        pagebreak()
        full-page-chapter.update(false)
        v(16pt)

        text(size: 26pt)[
          第 #counter(heading).display() 章
          #linebreak()
          #it.body
        ]

        v(20pt)
      }
    } else {
      full-page-chapter.update(false)
      v(3pt)
      [#it]
      v(8pt)
    }
  }

  // 顶部 header 文本
  if header != none {
    h(1fr)
    box(width: 60%)[
      #align(center)[
        #text(weight: "medium")[
          #header
        ]
      ]
    ]
    h(1fr)
  }

  // Logo 区域
  block[
    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(start + horizon)[
        #if school-logo == none {
          none
        } else {
          school-logo
        }
      ]
    ]

    #h(1fr)

    #box(height: IMAGE_BOX_MAX_HEIGHT, width: IMAGE_BOX_MAX_WIDTH)[
      #align(end + horizon)[
        #if company-logo != none {
          company-logo
        }
      ]
    ]
  ]

  // 标题区
  align(center + horizon)[
    #if subtitle != none {
      text(size: 14pt, tracking: 2pt)[
        #smallcaps[
          #subtitle
        ]
      ]
    }

    #line(length: 100%, stroke: 0.5pt)

    #text(size: 20pt, weight: "bold")[
      #title
    ]

    #line(length: 100%, stroke: 0.5pt)
  ]

  // 作者、导师
  box()
  h(1fr)

  grid(
    columns: (auto, 1fr),
    [
      #if authors.len() > 0 {
        [
          #text(weight: "bold")[
            作者
            #linebreak()
          ]

          #for author in authors {
            [#author #linebreak()]
          }
        ]
      }
    ],
    [
      #if mentors != none and mentors.len() > 0 {
        align(end)[
          #text(weight: "bold")[
            指导老师
            #linebreak()
          ]

          #for mentor in mentors {
            mentor
            linebreak()
          }
        ]
      }
    ],
  )

  // 底部信息
  align(center + bottom)[
    #if branch != none {
      branch
      linebreak()
    }

    #if academic-year != none {
      [#academic-year]
    }
  ]

  pagebreak()

  // 正文段落设置
  set par(
    first-line-indent: (amount: 2em, all: true),
    justify: true,
  )

  // 正文目录
  if show-toc {
    outline(
      title: [目录],
      depth: 3,
      indent: auto,
    )
  }

  // 正文
  body
}
