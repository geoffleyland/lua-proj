# lua-proj - Binding to [Proj.4](https://github.com/OSGeo/proj.4)

## 1. What?

Proj.4 is a library for converting coordinates between geographic projections.


## 2. How?

``luarocks install proj``

then

    local proj = require"proj"
    local nztm_to_wgs84 = proj:new("nztm", "wgs84 +degrees")
    print(nztm_to_wgs84(1600000, 6000000))    -- prints "173     -36.144718099788"
    print(nztm_to_wgs84:revert(173, -36))     -- prints "1600000    6016051.5467717"

    local wgs84_to_nztm = nztm_to_wgs84:reverse()
    print(wgs84_to_nztm(173, -36))            -- prints "1600000    6016051.5467717"

    wgs84_to_nztm:set_output("nzmg")
    print(wgs84_to_nztm(173, -36))            -- prints "2510588.5912768    6578340.6211262"


### Extensions to Proj.4

Proj.4 projection definition strings are hard to remember,
so lua-proj contains a list of shortcuts for projections I use frequently in
`proj/shortcuts.lua`
These are NZTM, NZMG and WGS84.
This list could be extended (perhaps by pull request?)

When Proj.4 does projections in "degrees", like WGS84, despite most of the
documentation saying "degrees", it actually means radians.
Sometimes it's more convenient to work in degrees (particularly if you're
reading a shapefile whose projection is in degrees).
lua-proj recognises `+degrees` in the projection definition string and
handles conversion from degrees to radians.
The `+degrees` is removed before the string is passed on to Proj.4.

Proj.4 has the options `+proj=latlong` and `+proj=longlat`.
Despite what you might think, these *both* expect coordinates to be passed in
in the order `longitude, latitude`.
Sometimes it's convenient (for example when parsing shapefiles) to work in
`latitude, longitude` order.
lua-proj recognises `+order=longlat` and `+order=latlong` and swaps the
coordinates as necessary.
As for `+degrees` the `+order=...` is removed before the string is passed
on to Proj.4.


## 3. Requirements

LuaJIT >= 2.0.0.


## 4. Alternatives

+ I don't know of any