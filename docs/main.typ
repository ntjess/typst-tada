#import "../lib.typ": *
#import "utils.typ": *
#import display: DEFAULT-TYPE-FORMATS

#set page(height: auto, margin: 0.2in, fill: white)
#let example-blocks = state("example-blocks", ())


#let inline-code(content) = box(
  radius: 0.25em,
  fill: rgb("#ddd8"),
  inset: 0.25em,
  baseline: 0.25em,
  content,
)

#show raw.where(block: false): inline-code

#set text(font: "Linux Libertine")
#let normal-show(content) = {
  example-blocks.update(old => {
    old.push(content.text)
    old
  })
  locate(loc => {
    let prefix = "#let to-tablex = (body) => {}\n
    #let output = to-tablex
    "
    for (ii, block) in example-blocks.at(loc).slice(0, -1).enumerate(start: 2) {
      prefix += block + "\n\n"
    }
    prefix += "
      #let to-tablex = tada.to-tablex
      #let output = (content) => { content }
    "
    example-with-source(
      prefix: prefix,
      content.text,
      tada: lib,
      direction: ltr,
    )
  })
}
#show raw.where(lang: "example"): normal-show

#let tada-box = box.with(stroke: black, inset: 2pt, baseline: 0.35em)
#show "TaDa": [#tada-box[Ta]#tada-box[Da]]

= Overview
TaDa provides a set of simple but powerful operations on rows of data.

Key features include:

- *Arithmetic expressions*: Row-wise operations are as simple as string expressions with field names

- *Aggregation*: Any function that operates on an array of values can perform row-wise or
  column-wise aggregation

- *Data representation*: Handle displaying currencies, floats, integers, and more
  with ease and arbitrary customization

#text(red)[Note: This library is in early development. The API is subject to change especially as typst adds more support for user-defined types. *Backwards compatibility is not guaranteed!* Handling of field info, value types, and more may change substantially with more user feedback.]

// Leave out for now
// #show outline.entry: it => {
//   link(it.element.location(), it.body)
// }
// #show outline.entry.where(
//   level: 1
// ): it => {
//   v(12pt, weak: true)
//   strong(it)
// }


// #outline(indent: 1em, fill: none, title: none)

== Importing
TaDa can be imported as follows:
#let tada-str = "tada:" + str(version)

=== From the official packages repository (recommended):
#raw(lang: "typst", block: true, "#import \"@preview/" + tada-str + "\"")

=== From the source code (not recommended)
*Option 1:* You can clone the package directly into your project directory:
  ```bash
  # In your project directory
  git clone https://github.com/ntjess/typst-tada.git tada
  ```
  Then import the functionality with ```typst #import "./tada/lib.typ"```

*Option 2:* If Python is available on your system,
  use the provided packaging script to install TaDa in typst's `local` directory:
  ```bash
  # Anywhere on your system
  git clone https://github.com/ntjess/typst-tada.git
  cd typst-tada
  # Replace $XDG_CACHE_HOME with the appropriate directory based on
  # https://github.com/typst/packages#downloads
  python package.py ./typst.toml "$XDG_CACHE_HOME/typst/packages" \
    --namespace local
  ``` 
  Now, TaDa is available under the local namespace:
  #raw(lang: "typst", block: true, "#import \"@local/" + tada-str + "\"")


= Table manipulation
TaDa provides two main ways to construct tables -- from columns and from rows:

```example
#let column-data = (
  name: ("Bread", "Milk", "Eggs"),
  price: (1.25, 2.50, 1.50),
  quantity: (2, 1, 3),
)
#let row-data = (
  (name: "Bread", price: 1.25, quantity: 2),
  (name: "Milk", price: 2.50, quantity: 1),
  (name: "Eggs", price: 1.50, quantity: 3),
)

// See `importing tada` above for reference
#let td = tada.from-columns(column-data)
// Equivalent to:
// #let td = TableData(rows: row-data)

// Show using `to-tablex`
// #let to-tablex = tada.to-tablex
#to-tablex(td)
```

== Title formatting
You can pass any `content` as a field's `title`. *Note*: if you pass a string, it will be evaluated as markup.
```example
#let fmt = it => heading(outlined: false, upper(it.at(0)) + it.slice(1))

#let titles = (
  name: (title: fmt), // as a function
  quantity: (title: fmt("Qty")), // as a string
  ..td.field-info,
)
// You can also provide defaults for any unspecified field info
#let defaults = (title: fmt)
#let td = TableData(..td, field-info: titles, field-defaults: defaults)

#to-tablex(td)
```

== Using `__index`

TaDa will automatically add an `__index` field to each row that is hidden by default. If you want it displayed, update its information to set ```typc hide: false```:

```example
// You can add new fields or update existing ones using `with-field`.
#let td = tada.with-field(td, "__index", hide: false, title: "\#")
// You can also insert attributes directly:
// #td.field-info.__index.insert("hide", false)
// etc.
#to-tablex(td)
```

== Value formatting

=== `type`
Type information can have attached metadata that specifies alignment, display formats, and more. Available types and their metadata are:
#raw(lang: "typc", repr(DEFAULT-TYPE-FORMATS)). While adding your own default types is not yet supported, you can simply defined
a dictionary of specifications and pass its keys to the field

```example
#let fmt-currency(val) = {
  // "negative" sign if needed
  let sign = if val < 0 {str.from-unicode(0x2212)} else {""}
  let currency = "$"
  [#sign#currency]
  tada.display.format-float(
    calc.abs(val), precision: 2, pad: true
  )
}
#let currency-info = (display: fmt-currency, align: right)
#td.field-info.insert("price", (type: "currency"))
#let td = TableData(..td, type-info: ("currency": currency-info))
#to-tablex(td)
```
== Transposing
`transpose` is supported, but keep in mind if columns have different types, an error will be a frequent result. To avoid the error, explicitly pass `ignore-types: true`. You can choose whether to keep field names as an additional column by passing a string to `fields-name` that is evaluated as markup:

```example
#to-tablex(
  transpose(td, ignore-types: true, fields-name: "")
)
```
// Leave this out until locales are handled more robustly
// === Currency and decimal locales
// You can account for your locale by updating `default-currency`, `default-hundreds-separator`, and `default-decimal`:
// ```example
// #to-tablex[
//   American: #format-currency(12.5)
  
// ]
// #default-currency.update("€")
// #to-tablex[
//   European: #format-currency(12.5)
// ]
// ```

// These changes will also impact how `currency` and `float` types are displayed in a table.

=== `display`
If your type is not available or you want to customize its display, pass a `display` function that formats the value, or a string that accesses `value` in its scope:
  
```example
#td.field-info.at("quantity").insert(
  "display",
  val => ("One", "Two", "Three").at(val - 1),
)

#let td = TableData(..td)
#to-tablex(td)
```

=== `align` etc.
You can pass `align` and `width` to a given field's metadata to determine how content aligns in the cell and how much horizontal space it takes up. In the future, more `tablex` setup arguments will be accepted.

```example
#let adjusted = td
#adjusted.field-info.at("name").insert("align", center)
#adjusted.field-info.at("name").insert("width", 1fr)
#to-tablex(
  TableData(..adjusted)
)
```

== Deeper `tablex` customization
TaDa uses `tablex` to display the table. So any argument that `tablex` accepts can be
passed to TableData as well:

```example
#let mapper = (index, row) => {
  let fill = if index == 0 {white.darken(15%)} else {none}
  row.map(cell => (..cell, fill: fill))
}
#let td = TableData(
  ..td,
  tablex-kwargs: (
    map-rows: mapper,
    auto-vlines: false,
  ),
)
#to-tablex(td)
```

== Subselection
You can select a subset of fields to display:

```example
#to-tablex(
  subset(td, indexes: (0,2), fields: ("__index", "name", "price"))
)
```

Rows can also be selected by whether they fulfill a field condition:
```example
#to-tablex(
  filter(td, expression: "price < 1.5")
)
```
= Operations

== Expressions
The easiest way to leverage TaDa's flexibility is through expressions. They can be strings that treat field names as variables, or functions that take keyword-only arguments.
- *Note*! When passing functions, every field is passed as a named argument to the function. So, make sure to capture unused fields with `..rest` (the name is unimportant) to avoid errors.

```example
#let td = tada.with-field(
  td,
  "total",
  expression: "price * quantity",
  type: "currency",
)

// Expressions can build off other expressions, too
#let taxed = tada.with-field(
  td,
  "Tax",
  // Expressions can be functions, too
  expression: (total: none, ..rest) => total * 0.2,
  type: "currency",
)

#to-tablex(taxed)
```

== Chaining
It is inconvenient to require several temporary variables as above, or deep function nesting, to perform multiple operations on a table. TaDa provides a `chain` function to make this easier:

```example
#let (chain, concat) = (tada.chain, tada.concat)
#let totals = chain(td,
  concat.with(
    field: "total",
    expression: "price * quantity",
    type: "currency",
  ),
  concat.with(
    field: "tax",
    expression: "total * 0.2",
    type: "currency",
  ),
  concat.with(
    field: "after tax",
    expression: "total + tax",
    title: fmt("w/ Tax"),
    type: "currency",
  ),
  subset.with(
    fields: ("name", "total", "after tax")
  ),
)

#to-tablex(totals)
```

== Aggregation
Row-wise and column-wise reduction is supported through `agg`:

```example
#let grand-total = chain(
  subset(totals, fields: "total"),
  agg.with(using: array.sum),
  // use "item" to extract the value when a table has exactly one element
  item
)
// "Output" is a helper function just for capturing example
// outputs. It is not necessary in your code.
#output[
  *Grand total: #fmt-currency(grand-total)*
]
```

It is also easy to aggregate over multiple fields:
```example
#let agg-td = agg(
  totals,
  using: array.sum,
  fields: ("total", "after tax"),
  axis: 0,
  title: "*#repr(function)\(#field\)*"
)
#to-tablex(agg-td)
```

= Roadmap
#let cb = box(stroke: black, width: 0.65em, height: 0.65em, baseline: 0.65em)
#set list(marker: cb)
- `apply` for value-wise transformations
- Reconcile whether `field-info` should be required
- `pivot`/`melt`
- `merge`/`join`
