
// https://github.com/ntjess/showman.git
#import "@preview/showman:0.1.2": runner, formatter

#import "../lib.typ" as tada

// redefine to ensure path is read here instead of from showman executor
#let local-csv(path) = csv(path)
#let template = formatter.template.with(
  // theme: "dark",
  eval-kwargs: (
    scope: (tada: tada, csv: local-csv),
    eval-prefix: "#let to-table(it) = output(tada.to-table(it))",
    direction: ltr,
  ),
)
#show: template

#let cache = json("/.coderunner.json").at("examples/titanic.typ", default: (:))
#show raw.where(lang: "python"): runner.external-code.with(result-cache: cache, direction: ttb)
#show <example-output>: set text(font: "Libertinus serif")

#set page(margin: 0.7in, height: auto)

= Poking around the `titanic` dataset
== First in Python

```python
import requests
from pathlib import Path

def download(url, output_file):
    if not Path(output_file).exists():
        r = requests.get(url)
        with open(output_file, "wb") as f:
            f.write(r.content)
    print("Download finished")

download("https://web.stanford.edu/class/archive/cs/cs109/cs109.1166/stuff/titanic.csv", "examples/titanic.csv")
```

```python
import pandas as pd
df = pd.read_csv("examples/titanic.csv")
df["Name"] = df["Name"].str.split(" ").str.slice(0, 3).str.join(" ")
df = df.drop(df.filter(like="Aboard", axis=1).columns, axis=1)

print(df.head(5))
```

= Can we do it in Typst?

```globalexample
#let csv-to-tabledata(file, n-rows: -2) = {
  let data = csv(file)
  let headers = data.at(0)
  let rows = data.slice(1, n-rows + 1)
  tada.from-rows(rows, field-info: headers)
}
#import tada: TableData, subset, chain, filter, update-fields, agg, sort-values
#let td = chain(
  csv-to-tabledata("/examples/titanic.csv"),
  // Shorten long names
  tada.add-expressions.with(
    Name: `Name.split(" ").slice(1, 3).join(" ")`,
  ),
)
#output[
  Data loaded!
  #chain(
    td,
    subset.with(
      fields: ("Name", "Age", "Fare"), indexes: range(3)
    ),
    to-table
  )
]
```

== Make it prettier
```globalexample
#let fill(x, y) = {
  let fill = none
  if y == 0 {
    fill = rgb("#8888")
  } else if calc.odd(y) {
    fill = rgb("#1ea3f288")
  }
  fill
}
#let title-fmt(name) = heading(outlined: false, name)
#td.table-kwargs.insert("fill", fill)
#td.field-defaults.insert("title", title-fmt)
#to-table(subset(td, fields: ("Name", "Age", "Fare"), indexes: range(0, 5)))
```

== Convert types & clean data
```globalexample
#let usd = tada.display.format-usd

#let td = chain(
  td,
  tada.add-expressions.with(
    Pclass: `int(Pclass)`,
    Name: `Name.slice(0, Name.position("("))`,
    Sex: `upper(Sex.at(0))`,
    Age: `float(Age)`,
    Fare: `float(Fare)`,
  ),
  update-fields.with(
    Fare: (display: usd),
  ),
  subset.with(
    fields: ("Pclass", "Name", "Age", "Fare")
  ),
  sort-values.with(by: "Fare", descending: true),
)
#to-table(subset(td, indexes: range(0, 10)))
```

== Find just the passengers over 30 paying over \$230
```globalexample
#to-table(filter(td, expression: `Age > 30 and Fare > 230`))
```

== See how much each class paid and their average age
```globalexample
#let fares-per-class = tada.group-by(
  td,
  by: "Pclass",
  aggs: (
    "Total Fare": `Fare.sum()`,
    "Avg Age": `int(Age.sum()/Age.len())`,
  ),
  field-info: ("Total Fare": (display: usd)),
)
#to-table(fares-per-class)
```
