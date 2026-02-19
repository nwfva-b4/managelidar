# Retrieve LASfile headers (metadata)

`get_header()` reads the metadata included in the headers of
LAS/LAZ/COPC files without loading the full point cloud. It works on
single files, directories, or Virtual Point Cloud (.vpc) files
referencing LASfiles.

## Usage

``` r
get_header(path, full.names = FALSE)
```

## Arguments

- path:

  Character. Path to a LAS/LAZ/COPC file, a directory containing
  LASfiles, or a Virtual Point Cloud (.vpc) file.

- full.names:

  Logical. If `TRUE`, the returned list is named with full file paths;
  if `FALSE` (default), the list is named with base filenames only.

## Value

A named list of `LASheader` S4 objects, one per file. Use
[`names()`](https://rdrr.io/r/base/names.html) to see the file names or
paths.

## Details

The function wraps
[`lidR::readLASheader()`](https://rdrr.io/pkg/lidR/man/readLASheader.html)
and allows quick access to metadata such as number of points, number of
returns, point format, and coordinate system, without loading the point
cloud into memory.

## Examples

``` r
folder <- system.file("extdata", package = "managelidar")
las_files <- list.files(folder, full.names = T, pattern = "*20240327.laz")

las_files |> get_header()
#> $`3dm_32_547_5724_1_ni_20240327.laz`
#> File signature:           LASF 
#> File source ID:           0 
#> Global encoding:
#>  - GPS Time Type: Standard GPS Time 
#>  - Synthetic Return Numbers: no 
#>  - Well Know Text: CRS is WKT 
#>  - Aggregate Model: false 
#> Project ID - GUID:        00000000-0000-0000-0000-000000000000 
#> Version:                  1.4
#> System identifier:         
#> Generating software:      lasr with LASlib 
#> File creation d/y:        123/2024
#> header size:              375 
#> Offset to point data:     3137 
#> Num. var. length record:  3 
#> Point data format:        7 
#> Point data record length: 42 
#> Num. of point records:    2936 
#> Num. of points by return: 2606 127 127 63 12 1 0 0 0 0 0 0 0 0 0 
#> Scale factor X Y Z:       0.001 0.001 0.001 
#> Offset X Y Z:             2e+06 6500000 0 
#> min X Y Z:                547690 5724000 222.866 
#> max X Y Z:                547999.7 5725000 316.283 
#> Variable Length Records (VLR):
#>    Variable Length Record 1 of 3 
#>        Description:  
#>        Tags:
#>           Key 3072 value 25832 
#>    Variable Length Record 2 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        WKT OGC COORDINATE SYSTEM: PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["Europea [...] (truncated)
#>    Variable Length Record 3 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        Extra Bytes Description:
#>           Amplitude: Echo signal amplitude [dB]
#>           Reflectance: Echo signal reflectance [dB]
#>           Deviation: Pulse shape deviation
#> Extended Variable Length Records (EVLR):  void
#> 
#> $`3dm_32_547_5725_1_ni_20240327.laz`
#> File signature:           LASF 
#> File source ID:           0 
#> Global encoding:
#>  - GPS Time Type: Standard GPS Time 
#>  - Synthetic Return Numbers: no 
#>  - Well Know Text: CRS is WKT 
#>  - Aggregate Model: false 
#> Project ID - GUID:        00000000-0000-0000-0000-000000000000 
#> Version:                  1.4
#> System identifier:         
#> Generating software:      lasr with LASlib 
#> File creation d/y:        123/2024
#> header size:              375 
#> Offset to point data:     3137 
#> Num. var. length record:  3 
#> Point data format:        7 
#> Point data record length: 42 
#> Num. of point records:    3369 
#> Num. of points by return: 1340 534 748 584 162 1 0 0 0 0 0 0 0 0 0 
#> Scale factor X Y Z:       0.001 0.001 0.001 
#> Offset X Y Z:             2e+06 6500000 0 
#> min X Y Z:                547648 5725000 223.448 
#> max X Y Z:                547998.1 5725991 316.526 
#> Variable Length Records (VLR):
#>    Variable Length Record 1 of 3 
#>        Description:  
#>        Tags:
#>           Key 3072 value 25832 
#>    Variable Length Record 2 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        WKT OGC COORDINATE SYSTEM: PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["Europea [...] (truncated)
#>    Variable Length Record 3 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        Extra Bytes Description:
#>           Amplitude: Echo signal amplitude [dB]
#>           Reflectance: Echo signal reflectance [dB]
#>           Deviation: Pulse shape deviation
#> Extended Variable Length Records (EVLR):  void
#> 
#> $`3dm_32_548_5724_1_ni_20240327.laz`
#> File signature:           LASF 
#> File source ID:           0 
#> Global encoding:
#>  - GPS Time Type: Standard GPS Time 
#>  - Synthetic Return Numbers: no 
#>  - Well Know Text: CRS is WKT 
#>  - Aggregate Model: false 
#> Project ID - GUID:        00000000-0000-0000-0000-000000000000 
#> Version:                  1.4
#> System identifier:         
#> Generating software:      lasr with LASlib 
#> File creation d/y:        123/2024
#> header size:              375 
#> Offset to point data:     3137 
#> Num. var. length record:  3 
#> Point data format:        7 
#> Point data record length: 42 
#> Num. of point records:    10000 
#> Num. of points by return: 3426 1998 2228 1755 558 33 2 0 0 0 0 0 0 0 0 
#> Scale factor X Y Z:       0.001 0.001 0.001 
#> Offset X Y Z:             2e+06 6500000 0 
#> min X Y Z:                548000 5724000 224.578 
#> max X Y Z:                548992 5724997 372.281 
#> Variable Length Records (VLR):
#>    Variable Length Record 1 of 3 
#>        Description:  
#>        Tags:
#>           Key 3072 value 25832 
#>    Variable Length Record 2 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        WKT OGC COORDINATE SYSTEM: PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["Europea [...] (truncated)
#>    Variable Length Record 3 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        Extra Bytes Description:
#>           Amplitude: Echo signal amplitude [dB]
#>           Reflectance: Echo signal reflectance [dB]
#>           Deviation: Pulse shape deviation
#> Extended Variable Length Records (EVLR):  void
#> 
#> $`3dm_32_548_5725_1_ni_20240327.laz`
#> File signature:           LASF 
#> File source ID:           0 
#> Global encoding:
#>  - GPS Time Type: Standard GPS Time 
#>  - Synthetic Return Numbers: no 
#>  - Well Know Text: CRS is WKT 
#>  - Aggregate Model: false 
#> Project ID - GUID:        00000000-0000-0000-0000-000000000000 
#> Version:                  1.4
#> System identifier:         
#> Generating software:      lasr with LASlib 
#> File creation d/y:        123/2024
#> header size:              375 
#> Offset to point data:     3137 
#> Num. var. length record:  3 
#> Point data format:        7 
#> Point data record length: 42 
#> Num. of point records:    10000 
#> Num. of points by return: 4247 1657 2105 1482 489 17 2 1 0 0 0 0 0 0 0 
#> Scale factor X Y Z:       0.001 0.001 0.001 
#> Offset X Y Z:             2e+06 6500000 0 
#> min X Y Z:                548000 5725000 232.946 
#> max X Y Z:                548995.4 5725992 385.486 
#> Variable Length Records (VLR):
#>    Variable Length Record 1 of 3 
#>        Description:  
#>        Tags:
#>           Key 3072 value 25832 
#>    Variable Length Record 2 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        WKT OGC COORDINATE SYSTEM: PROJCRS["ETRS89 / UTM zone 32N",BASEGEOGCRS["ETRS89",ENSEMBLE["Europea [...] (truncated)
#>    Variable Length Record 3 of 3 
#>        Description: by LAStools of rapidlasso GmbH 
#>        Extra Bytes Description:
#>           Amplitude: Echo signal amplitude [dB]
#>           Reflectance: Echo signal reflectance [dB]
#>           Deviation: Pulse shape deviation
#> Extended Variable Length Records (EVLR):  void
#> 
```
