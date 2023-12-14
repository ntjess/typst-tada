////
// Inspiration: https://github.com/typst/packages/blob/main/packages/preview/cetz/0.1.0/manual.typ
////

#import "../lib.typ"
#import "@preview/tidy:0.1.0"

#let example-blocks = state("example-blocks", ())

#let raw-background(..args) = {
  box(fill: rgb("#8884"), inset: 0.5em, radius: 0.5em, ..args)
}
// This is a wrapper around typs-doc show-module that
// strips all but one function from the module first.
// As soon as typst-doc supports examples, this is no longer
// needed.
#let show-module-fn(module, fn, ..args) = {
  module.functions = module.functions.filter(f => f.name == fn)
  tidy.show-module(
    module, ..args.pos(), ..args.named(), show-module-name: false
  )
}


#let format-raw(it, lang: none, line-numbers: true, ..background-kwargs) = {
  let raw-background = raw-background.with(..background-kwargs)
  let it = raw-background(raw(it, lang: lang))
  if line-numbers {
    show raw.line: it => {
      box(
        grid(columns: 2, column-gutter: 0.5em)[
          #style(styles => {
            let reserved = measure(text[#it.count], styles).width
            box(text(fill: gray)[#it.number], width: reserved)
          })
        ][#it]
      )
    }
    it
  } else {
    it
  }
}


// --- Evaluating an example and capturing the output ---

#let _build-preamble(scope, unpack-modules: false) = {
  let preamble = ""
  for key in scope.keys() {
    if type(scope.at(key)) == module and unpack-modules {
      preamble = preamble + "import " + key + ": *; "
    }
  }
  preamble
}

#let eval-example(source, prefix: "", suffix: "", unpack-modules: false, scope: (:)) = {
  let preamble = _build-preamble(scope, unpack-modules: unpack-modules)
  let pieces = (prefix, source, suffix)
  eval(
    (preamble + "\n[\n" + pieces.join("\n") + "\n]"), scope: scope
  )
}

#let _bidir-grid(direction, ..args) = {
  let n-args = args.pos().len()
  let grid-kwargs = (:)
  if direction == ltr {
    grid-kwargs = (columns: n-args, column-gutter: 1em)
  } else {
    grid-kwargs = (rows: n-args, row-gutter: 1em, columns: (100%,))
  }
  grid(..grid-kwargs, ..args)
}

#let py-code(input, ..output, direction: ttb, scope: (:)) = {
  let input-source = input.text
  [#metadata(input-source)<py-code>]
  input = format-raw(input.text, lang: "python", width: 100%)
  output = output.pos()
  _bidir-grid(direction, input, ..output)
}

#let code-result(content) = [#content<code-result>]

#let standalone-example(source, direction: ttb, ..args) = {
  let picture = eval-example(source.text, ..args)
  let fmt-source = [
    // For some reason, `raw` formatting still gets applied even if you extract
    // `source.text`. So compensate for the smaller text size by manually increasing it
    // beforehand
    #show raw: set text(size: 1.25em)
    #format-raw(lang: "typ", source.text, width: 1fr)
  ]

  let grid-args = (fmt-source, )
  if picture != none {
    grid-args.push[
      #set text(font: "Linux Libertine")
      #raw-background(picture)
    ]
  }
  _bidir-grid(direction, ..grid-args)
}


#let global-example(content, prefix-initializer: "", prefix-finalizer: "", ..args) = {
  example-blocks.update(old => {
    old.push(content.text)
    old
  })
  locate(loc => {
    let prefix = "#let output = (body) => {}\n" + prefix-initializer + "\n"
    for block in example-blocks.at(loc).slice(0, -1) {
      prefix += block + "\n\n"
    }
    prefix += "#let output = (content) => { content }\n" + prefix-finalizer + "\n"
    let named = args.named()
    named.insert("prefix", prefix)
    standalone-example(content, ..named)
  })
}


#let template(
  body,
  theme: "light",
  eval-kwargs: (:),
  global-example-prefix-initializer: "",
  global-example-prefix-finalizer: "",
) = {
  // Formatting inline raw code
  show raw.where(block: false): raw-background.with(
    radius: 0.25em, inset: 0.25em, baseline: 0.25em, width: auto
  )
  show raw.where(block: true): it => block(raw-background(it, width: 100%))
  show raw.where(lang: "standalone-example"): standalone-example.with(..eval-kwargs)
  show raw.where(lang: "example"): standalone-example.with(..eval-kwargs)
  show raw.where(lang: "global-example"): global-example.with(
    ..eval-kwargs,
    prefix-initializer: global-example-prefix-initializer,
    prefix-finalizer: global-example-prefix-finalizer,
  )
  set text(font: "Linux Libertine")
  if theme == "dark" {
    set text(fill: white)
    set page(fill: black)
    body
  } else {
    set page(fill: white) // so text shows in svg in dark mode browsers
    body
  }
}
