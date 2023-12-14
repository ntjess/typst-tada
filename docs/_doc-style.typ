#import "@preview/tidy:0.1.0"
#import tidy.styles.default: *

#let show-parameter-block(
  name, types, content, style-args,
  show-default: false,
  default: none,
) = block(
  inset: 10pt, fill: rgb("ddd3"), width: 100%,
  breakable: style-args.break-param-descriptions,
  [
    #text(weight: "bold", size: 1.1em, name)
    #h(.5cm)
    #types.map(x => (style-args.style.show-type)(x)).join([ #text("or",size:.6em) ])

    #content
    #if show-default [ #parbreak() Default: #raw(lang: "typc", default) ]
  ]
)

#let type-colors = (
  "content": rgb("#a6ebe699"),
  "color": rgb("#a6ebe699"),
  "string": rgb("#d1ffe299"),
  "none": rgb("#ffcbc499"),
  "auto": rgb("#ffcbc499"),
  "boolean": rgb("#ffedc199"),
  "integer": rgb("#e7d9ff99"),
  "float": rgb("#e7d9ff99"),
  "ratio": rgb("#e7d9ff99"),
  "length": rgb("#e7d9ff99"),
  "angle": rgb("#e7d9ff99"),
  "relative-length": rgb("#e7d9ff99"),
  "fraction": rgb("#e7d9ff99"),
  "symbol": rgb("#eff0f399"),
  "array": rgb("#eff0f399"),
  "dictionary": rgb("#eff0f399"),
  "arguments": rgb("#eff0f399"),
  "selector": rgb("#eff0f399"),
  "module": rgb("#eff0f399"),
  "stroke": rgb("#eff0f399"),
  "function": rgb("#f9dfff99"),
)
#let get-type-color(type) = type-colors.at(type, default: rgb("#eff0f333"))

// Create beautiful, colored type box
#let show-type(type) = {
  h(2pt)
  box(outset: 2pt, fill: get-type-color(type), radius: 2pt, raw(type))
  h(2pt)
}