-- luacheck: std max+busted

local proj = require"proj"

describe("proj", function()

  test("init", function()
    assert.has.no.error(function() proj:new("nztm", "wgs84") end)
  end)

  test("bad_init", function()
    assert.has_error(function() proj:new("this is not a projection", "wgs84") end,
      "proj.read_proj_string: Error in projection 'this is not a projection': no arguments in initialization list")
  end)


  test("convert and revert", function()
    local P1 = proj:new("nztm", "wgs84")
    local x, y = P1:revert(P1(1600000, 6000000))
    assert.near(1600000, x, 1e-9)
    assert.near(6000000, y, 1e-9)

    local P2 = proj:new("wgs84 +degrees", "nztm")
    x, y = P2:revert(P2:convert(173, -36))
    assert.near(173, x, 1e-9)
    assert.near(-36, y, 1e-9)
    x, y = P2(173, -36)

    local P3 = proj:new("wgs84 +degrees +order=latlong", "nztm")
    local x2, y2 = P3(-36, 173)
    assert.equal(x, x2)
    assert.equal(y, y2)
  end)

  test("auto identity", function()
    local P1 = proj:new("nztm", "nztm")
    local x, y = P1(1600000, 6000000)
    assert.equal(1600000, x)
    assert.equal(6000000, y)
  end)

  test("explicit identity", function()
    local P1 = proj:identity()
    local x, y = P1(1600000, 6000000)
    assert.equal(1600000, x)
    assert.equal(6000000, y)

    x, y = P1:convert(1600000, 6000000)
    assert.equal(1600000, x)
    assert.equal(6000000, y)

    x, y = P1:revert(1600000, 6000000)
    assert.equal(1600000, x)
    assert.equal(6000000, y)
  end)

  test("reverse", function()
    local P1 = proj:new("nztm", "wgs84")
    local P2 = P1:reverse()
    local x, y = P2(P1(1600000, 6000000))
    assert.near(1600000, x, 1e-9)
    assert.near(6000000, y, 1e-9)
  end)

  test("set input & output", function()
    local P1 = proj:new()
    P1:set_input("nztm")
    P1:set_output("wgs84")
    local x, y = P1:revert(P1(1600000, 6000000))
    assert.near(1600000, x, 1e-9)
    assert.near(6000000, y, 1e-9)
  end)

end)