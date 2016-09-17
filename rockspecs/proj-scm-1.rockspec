package = "proj"
version = "scm-1"
source =
{
  url = "git://github.com/geoffleyland/lua-proj.git"
}
description =
{
  summary = "A simple (too simple?) binding to proj.4",
  homepage = "https://github.com/geoffleyland/lua-proj",
  license = "MIT/X11",
  maintainer = "Geoff Leyland <geoff.leyland@incremental.co.nz>",
}
dependencies =
{
  "lua >= 5.1",
}
external_dependencies =
{
  PROJ = { header = "proj_api.h" },
}
build =
{
  type = "builtin",
  modules =
  {
    proj = "src-lua/proj.lua",
    ["proj/shortcuts"] = "src-lua/proj/shortcuts.lua",
    proj_core =
    {
      sources = { "c/proj_core.c" },
      libraries = { "proj" },
    }
  },
}
