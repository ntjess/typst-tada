////
// Inspiration: https://github.com/typst/packages/blob/main/packages/preview/cetz/0.1.0/manual.typ
////

#import "../lib.typ"

#let example-blocks = state("example-blocks", ())

#let raw-background(inline: false, ..args) = {
  let container = if inline { box.with(baseline: 0.35em) } else { block.with(breakable: false) }
  container(fill: rgb("#8884"), inset: 0.35em, radius: 0.35em, ..args)
}

#let _add-raw-line-numbers(it) = {
  box(
    grid(columns: 2, column-gutter: 0.5em)[
      #style(styles => {
        let reserved = measure(text[#it.count], styles).width
        box(text(fill: gray)[#it.number], width: reserved)
      })
    ][#it]
  )
}

#let raw-line-numbering-background(it, line-numbers: true, ..background-kwargs) = {
  show raw.line: it => if line-numbers { _add-raw-line-numbers(it) } else { it }
  raw-background(it, ..background-kwargs)
}

#let _bidir-grid(direction, expand-first-item: true, ..args) = {
  let n-args = args.pos().len()
  let grid-kwargs = (:)
  if direction == ltr {
    grid-kwargs = (columns: (auto,) * n-args, column-gutter: 1em)
  } else {
    grid-kwargs = (rows: n-args, row-gutter: 1em)
  }
  grid(..grid-kwargs, ..args)
}

#let _fetch-result-from-cache(result-cache, index: -1) = {
  let result = result-cache.at("result", default: ())
  if result.len() == 0 {
    return none
  }
  result.at(index, default: none)
}

#let external-code(raw-content, result-cache: (:), direction: ttb, scope: (:)) = {
  let input-source = raw-content.text
  let lang = raw-content.at("lang", default: "default")
  [#metadata(input-source)#label(lang)]
  locate(loc => {
    let idx = query(label(lang), loc).len() - 1
    let output = _fetch-result-from-cache(result-cache, index: idx)
    if output == none {
      raw-content
    } else {
      _bidir-grid(direction, raw-content, ..output)
    }
  })
}

#let wilcard-import-string-from-modules(scope) = {
  let preamble = ()
  for key in scope.keys() {
    if type(scope.at(key)) == module {
      preamble.push("#import " + key + ": *")
    }
  }
  preamble.join("\n")
}

#let raw-with-eval(
  raw-content,
  direction: ttb,
  eval-prefix: "",
  eval-suffix: "",
  unpack-modules: false,
  scope: (:),
) = {
  let pieces = (eval-prefix, raw-content.text, eval-suffix)
  if unpack-modules {
    pieces.insert(0, wilcard-import-string-from-modules(scope))
  }
  let output = eval(pieces.join("\n"), mode: "markup", scope: scope)

  let grid-args = (box(width: 1fr)[#raw-content<example-input>], )
  grid-args.push[
    #set text(font: "Linux Libertine")
    #output<example-output>
  ]
  _bidir-grid(direction, ..grid-args)
}


#let global-example(raw-content, prefix-initializer: "", prefix-finalizer: "", ..args) = {
  example-blocks.update(old => {
    old.push(raw-content.text)
    old
  })
  locate(loc => {
    let all-blocks = ()
    all-blocks.push("#let output = (body) => {}")
    all-blocks.push(prefix-initializer)
    for block in example-blocks.at(loc).slice(0, -1) {
      all-blocks.push(block)
    }
    all-blocks.push("#let output = (content) => { content }")
    all-blocks.push(prefix-finalizer)
    let named = args.named()
    named.insert("eval-prefix", all-blocks.join("\n"))
    raw-with-eval(raw-content, ..args.pos(), ..named)
  })
}

#let format-raw-as-runnable(
  it,
  global: false,
  eval-kwargs: (:),
  global-example-prefix-initializer: "",
  global-example-prefix-finalizer: "",
) = {
  if global {
    global-example(
      it, 
      ..eval-kwargs,
      prefix-initializer: global-example-prefix-initializer,
      prefix-finalizer: global-example-prefix-finalizer,
    )
  } else {
    raw-with-eval(it, ..eval-kwargs)
  }
}


#let template(
  body,
  theme: "light",
  background-kwargs: (:),
  ..runnable-kwargs
) = {
  // Formatting inline raw code
  show raw.where(block: false): raw-background.with(inline: true, ..background-kwargs)
  show raw.where(block: true): raw-line-numbering-background.with(width: 100%, ..background-kwargs)
  show raw.where(block: true): it => {
    if "example" in it.lang {
      // Raw style will be double applied which shrinks text, so preemptively undo the
      // shrinking
      set text(size: 1.25em)
      let global = "global" in it.lang
      it = raw(it.text, lang: "typ", block: it.block)
      format-raw-as-runnable(it, global: global, ..runnable-kwargs)
    } else {
      it
    }
  }
  show <example-output>: raw-background.with(..background-kwargs)

  set text(font: "Linux Libertine")
  // Add variables here to avoid triggering error in Pandoc 3.1.10
  let _ = ""
  if theme == "dark" {
    set text(fill: white)
    set page(fill: black)
    body
  } else {
    body
  }
}
