#import "../lib.typ"
// Use "let =" instead of "import as" to be compatible with pandoc 3.1.10
#let tada = lib
#let DEFAULT-TYPE-FORMATS = tada.display.DEFAULT-TYPE-FORMATS
#import "docutils.typ": template

#show: template.with(
  // theme: "dark",
  eval-kwargs: (
    direction: ltr,
    scope: (tada: tada),
  ),
  global-example-prefix-initializer: "#let to-tablex = output",
  global-example-prefix-finalizer: "#let to-tablex = tada.to-tablex",
)

= Overview
TaDa provides a set of simple but powerful operations on rows of data. A full manual is
available online: #link(
  "https://github.com/ntjess/typst-tada/blob/v" + str(tada.tada-version) + "/docs/manual.pdf"
)

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

#let _make-import-stmt(namespace) = {
  let import-str = "#import \"@" + namespace + "/tada:" + str(tada.tada-version) + "\""
  raw(lang: "typst", block: true, import-str)
}

// #outline(indent: 1em, fill: none, title: none)
== Importing
TaDa can be imported as follows:

=== From the official packages repository (recommended):
#_make-import-stmt("preview")

=== From the source code (not recommended)
*Option 1:* You can clone the package directly into your project directory:
```bash
# In your project directory
git clone https://github.com/ntjess/typst-tada.git tada
```
Then import the functionality with
```typst #import "./tada/lib.typ" ```

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

  #_make-import-stmt("local")


= Table adjustment
== Creation
TaDa provides three main ways to construct tables -- from columns, rows, or records.
- *Columns* are a dictionary of field names to column values. Alternatively, a 2D array
  of columns can be passed to `from-columns`, where `values.at(0)` is a column (belongs
  to one field).
- *Records* are a 1D array of dictionaries where each dictionary is a row.
- *Rows* are a 2D array where `values.at(0)` is a row (has one value for each field).
  Note that if `rows` are given without field names, they default to (0, 1, ..$n$).

```globalexample
#let column-data = (
  name: ("Bread", "Milk", "Eggs"),
  price: (1.25, 2.50, 1.50),
  quantity: (2, 1, 3),
)
#let record-data = (
  (name: "Bread", price: 1.25, quantity: 2),
  (name: "Milk", price: 2.50, quantity: 1),
  (name: "Eggs", price: 1.50, quantity: 3),
)
#let row-data = (
  ("Bread", 1.25, 2),
  ("Milk", 2.50, 1),
  ("Eggs", 1.50, 3),
)

#import tada: TableData
#let td = TableData(data: column-data)
// Equivalent to:
#let td2 = tada.from-records(record-data)
// _Not_ equivalent to (since field names are unknown):
#let td3 = tada.from-rows(row-data)

#to-tablex(td)
#to-tablex(td2)
#to-tablex(td3)
```

== Title formatting
You can pass any `content` as a field's `title`. *Note*: if you pass a string, it will be evaluated as markup.

```globalexample
#let fmt(it) = {
  heading(outlined: false,
    upper(it.at(0))
    + it.slice(1).replace("_", " ")
  )
}

#let titles = (
  // As a function
  name: (title: fmt),
  // As a string
  quantity: (title: fmt("Qty")),
)
#let td = TableData(..td, field-info: titles)

#to-tablex(td)
```

== Adapting default behavior
You can specify defaults for any field not explicitly populated by passing information to
`field-defaults`. Observe in the last example that `price` was not given a title. We can
indicate it should be formatted the same as `name` by passing `title: fmt` to `field-defaults`. *Note* that any field that is explicitly given a value will not be affected by `field-defaults` (i.e., `quantity` will retain its string title "Qty")

```globalexample
#let defaults = (title: fmt)
#let td = TableData(..td, field-defaults: defaults)
#to-tablex(td)
```

== Using `__index`

TaDa will automatically add an `__index` field to each row that is hidden by default. If you want it displayed, update its information to set `hide: false`:

```globalexample
// Use the helper function `update-fields` to update multiple fields
// and/or attributes
#import tada: update-fields
#let td = update-fields(
  td, __index: (hide: false, title: "\#")
)
// You can also insert attributes directly:
// #td.field-info.__index.insert("hide", false)
// etc.
#to-tablex(td)
```

== Value formatting

=== `type`
Type information can have attached metadata that specifies alignment, display formats, and more. Available types and their metadata are:
#for (typ, info) in DEFAULT-TYPE-FORMATS [
  - *#typ* : #info
]

While adding your own default types is not yet supported, you can simply defined
a dictionary of specifications and pass its keys to the field

```globalexample
#let currency-info = (
  display: tada.display.format-usd, align: right
)
#td.field-info.insert("price", (type: "currency"))
#let td = TableData(..td, type-info: ("currency": currency-info))
#to-tablex(td)
```

== Transposing
`transpose` is supported, but keep in mind if columns have different types, an error will be a frequent result. To avoid the error, explicitly pass `ignore-types: true`. You can choose whether to keep field names as an additional column by passing a string to `fields-name` that is evaluated as markup:

```globalexample
#to-tablex(
  tada.transpose(
    td, ignore-types: true, fields-name: ""
  )
)
```

// Leave this out until locales are handled more robustly
// === Currency and decimal locales
// You can account for your locale by updating `default-currency`, `default-hundreds-separator`, and `default-decimal`:
// ```globalexample
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
  
```globalexample
#td.field-info.at("quantity").insert(
  "display",
  val => ("/", "One", "Two", "Three").at(val),
)

#let td = TableData(..td)
#to-tablex(td)
```

=== `align` etc.
You can pass `align` and `width` to a given field's metadata to determine how content aligns in the cell and how much horizontal space it takes up. In the future, more `tablex` setup arguments will be accepted.

```globalexample
#let adjusted = update-fields(
  td, name: (align: center, width: 1.4in)
)
#to-tablex(adjusted)
```

== Deeper `tablex` customization
TaDa uses `tablex` to display the table. So any argument that `tablex` accepts can be
passed to TableData as well:

```globalexample
#let mapper = (index, row) => {
  let fill = if index == 0 {rgb("#8888")} else {none}
  row.map(cell => (..cell, fill: fill))
}
#let td = TableData(
  ..td,
  tablex-kwargs: (
    map-rows: mapper, auto-vlines: false
  ),
)
#to-tablex(td)
```

== Subselection
You can select a subset of fields or rows to display:

```globalexample
#import tada: subset
#to-tablex(
  subset(td, indexes: (0,2), fields: ("name", "price"))
)
```

Note that `indexes` is based on the table's `__index` column, _not_ it's positional index within the table:
```globalexample
#let td2 = td
#td2.data.insert("__index", (1, 2, 2))
#to-tablex(
  subset(td2, indexes: 2, fields: ("__index", "name"))
)
```

Rows can also be selected by whether they fulfill a field condition:
```globalexample
#to-tablex(
  tada.filter(td, expression: "price < 1.5")
)
```

== Concatenation
Concatenating rows and columns are both supported operations, but only in the simple sense of stacking the data. Currently, there is no ability to join on a field or otherwise intelligently merge data.
- `axis: 0` places new rows below current rows
- `axis: 1` places new columns to the right of current columns
- Unless you specify a fill value for missing values, the function will panic if the tables do not match exactly along their concatenation axis.
- You cannot stack with `axis: 1` unless every column has a unique field name.

```globalexample
#import tada: stack

#let td2 = TableData(
  data: (
    name: ("Cheese", "Butter"),
    price: (2.50, 1.75),
  )
)
#let td3 = TableData(
  data: (
    rating: (4.5, 3.5, 5.0, 4.0, 2.5),
  )
)

// This would fail without specifying the fill
// since `quantity` is missing from `td2`
#let stack-a = stack(td, td2, missing-fill: 0)
#let stack-b = stack(stack-a, td3, axis: 1)
#to-tablex(stack-b)
```

= Operations

== Expressions
The easiest way to leverage TaDa's flexibility is through expressions. They can be strings that treat field names as variables, or functions that take keyword-only arguments.
- *Note*! When passing functions, every field is passed as a named argument to the function. So, make sure to capture unused fields with `..rest` (the name is unimportant) to avoid errors.

```globalexample
#let make-dict(field, expression) = {
  let out = (:)
  out.insert(
    field,
    (expression: expression, type: "currency"),
  )
  out
}

#let td = update-fields(
  td, ..make-dict("total", "price * quantity" )
)

#let tax-expr(total: none, ..rest) = { total * 0.2 }
#let taxed = update-fields(
  td, ..make-dict("tax", tax-expr),
)

#to-tablex(
  subset(taxed, fields: ("name", "total", "tax"))
)
```

== Chaining
It is inconvenient to require several temporary variables as above, or deep function nesting, to perform multiple operations on a table. TaDa provides a `chain` function to make this easier. Furthermore, when you need to compute several fields at once and don't need extra field information, you can use `add-expressions` as a shorthand:

```globalexample
#import tada: chain, add-expressions
#let totals = chain(td,
  add-expressions.with(
    total: "price * quantity",
    tax: "total * 0.2",
    after-tax: "total + tax",
  ),
  subset.with(
    fields: ("name", "total", "after-tax")
  ),
  // Add type information
  update-fields.with(
    after-tax: (type: "currency", title: fmt("w/ Tax")),
  ),
)
#to-tablex(totals)
```

== Sorting
You can sort by ascending/descending values of any field, or provide your own transformation function to the `key` argument to customize behavior further:
```globalexample
#import tada: sort-values
#to-tablex(sort-values(
  td, by: "quantity", descending: true
))
```

== Aggregation
Column-wise reduction is supported through `agg`, using either functions or string expressions:

```globalexample
#import tada: agg, item
#let grand-total = chain(
  totals,
  agg.with(after-tax: array.sum),
  // use "item" to extract exactly one element
  item
)
// "Output" is a helper function just for these docs.
// It is not necessary in your code.
#output[
  *Grand total: #tada.display.format-usd(grand-total)*
]
```

It is also easy to aggregate several expressions at once:
```globalexample
#let agg-exprs = (
  "# items": "quantity.sum()",
  "Longest name": "[#name.sorted(key: str.len).at(-1)]",
)
#let agg-td = tada.agg(td, ..agg-exprs)
#to-tablex(agg-td)
```
