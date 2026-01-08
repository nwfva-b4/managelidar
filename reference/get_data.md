# Get data in a standardized format and structure

This function copies data from one folder to another folder, while
ensuring certain data formating and folder structure. CRS is set, points
are sorted, files are compressed, files are renamed according to [ADV
standard](https://www.adv-online.de/AdV-Produkte/Standards-und-Produktblaetter/Standards-der-Geotopographie/binarywriterservlet?imgUid=6b510f6e-a708-d081-505a-20954cd298e1&uBasVariant=11111111-1111-1111-1111-111111111111),
files are ordered in folders by acquisition date and campaign, a VPC is
created and files are spatially indexed as COPC.

## Usage

``` r
get_data(
  origin,
  destination,
  campaign,
  origin_recurse = FALSE,
  prefix = "3dm",
  zone = 32,
  region = NULL,
  year = NULL,
  verbose = FALSE
)
```

## Arguments

- origin:

  path. The path to a directory which contains las/laz files

- destination:

  path. The directory under which the processed files are copied and
  subfolders (year/campaign) are created

- campaign:

  character. Name of the project or campaign of data acquisition.

- origin_recurse:

  boolean. Should files in subfolder be included?

- prefix:

  3 letter character. Naming prefix (defaults to "3dm")

- zone:

  2 digits integer. UTM zone (defaults to 32)

- region:

  2 letter character. (optional) federal state abbreviation. It will be
  fetched automatically if not defined (default).

- year:

  YYYY. (optional) acquisition year to append to filename. If not
  provided (default) the year will be extracted from the files. It will
  be the acquisition date if points contain datetime in GPStime format,
  otherwise it will get the year from the file header, which is the
  processing date by definition.

## Value

A structured copy of input lidar data

## Examples

``` r
if (FALSE) { # \dontrun{
f <- system.file("extdata", package = "managelidar")
get_data(f, tempdir(), "landesbefliegung")
} # }
```
