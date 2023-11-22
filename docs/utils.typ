////
// Inspiration: https://github.com/typst/packages/blob/main/packages/preview/cetz/0.1.0/manual.typ
////

#import "../lib.typ"
#import "@preview/tidy:0.1.0"

#let example-box = box.with(fill: white.darken(3%), inset: 0.5em, radius: 0.5em, width: 100%)
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


#let _build-preamble(scope) = {
  let preamble = ""
  for key in scope.keys() {
    if type(scope.at(key)) == module {
      preamble = preamble + "import " + key + ": *; "
    }
  }
  preamble
}

#let eval-example(source, prefix: "", suffix: "", ..scope) = {
  let preamble = _build-preamble(scope.named())
  let pieces = (prefix, source, suffix)
  eval(
    (preamble + "\n[\n" + pieces.join("\n") + "\n]"), scope: scope.named()
  )
}

#let _bidir-grid(direction, ..args) = {
  let grid-kwargs = (:)
  if direction == ltr {
    grid-kwargs = (columns: 2, column-gutter: 1em)
  } else {
    grid-kwargs = (rows: 2, row-gutter: 1em, columns: (100%,))
  }
  grid(..grid-kwargs, ..args)
}

#let example-with-source(source, inline: false, direction: ttb, ..scope) = {
    let picture = eval-example(source, ..scope)
    let source-box = if inline {box} else {block}
    
    _bidir-grid(direction)[
      #example-box(raw(lang: "typ", source))
    ][
      #set text(font: "Linux Libertine")
      #example-box(picture)
    ]

}