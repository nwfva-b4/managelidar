# Add or update a child link on a parent object

If a child link with this href already exists, its title is updated in
place (so renaming a collection also updates its listing in the parent);
otherwise a new child link is appended.

## Usage

``` r
add_child_link(parent_obj, child_rel_path, child_title = NULL)
```

## Arguments

- parent_obj:

  Parent STAC object (list)

- child_rel_path:

  Relative path to child from parent directory

- child_title:

  Optional title for the link

## Value

Updated parent object

## Details

Hrefs are compared as plain character strings (via
[`as.character()`](https://rdrr.io/r/base/character.html)), not with
[`identical()`](https://rdrr.io/r/base/identical.html). A freshly built
href from [`fs::path()`](https://fs.r-lib.org/reference/path.html)
carries an `fs_path` S3 class, but an href read back from JSON via
[`read_stac()`](https://wiesehahn.github.io/managelidar/reference/read_stac.md)
is a plain character string after the round-trip -
[`identical()`](https://rdrr.io/r/base/identical.html) treats those as
different even when the string content matches, which silently defeated
this match on every call after the first (each "update" appended a
duplicate child link instead).
