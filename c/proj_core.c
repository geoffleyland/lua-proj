/*******************************************************************************

Copyright (c) 2014-2016 Geoff Leyland
see LICENSE for license information

*******************************************************************************/

#include "proj_api.h"

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

LUALIB_API int luaopen_proj_core(lua_State *L);

const char *PROJECTION_METATABLE_NAME = "luaproj.projection";


/*--------------------------------------------------------------------------*/

static int luaproj_init(lua_State *L)
{
  const char *init_string = luaL_checkstring(L, 1);
  projPJ P = pj_init_plus(init_string);

  if (P)
  {
    projPJ *v = lua_newuserdata(L, sizeof(projPJ *));
    *v = P;
    luaL_getmetatable(L, PROJECTION_METATABLE_NAME);
    lua_setmetatable(L, -2);
    return 1;
  }
  else
  {
    lua_pushnil(L);
    return 1;
  }
}


static int luaproj_free(lua_State *L)
{
  projPJ *v = (projPJ*)luaL_checkudata(L, 1, PROJECTION_METATABLE_NAME);
  pj_free(*v);
  return 0;
}


static int luaproj_is_latlong(lua_State *L)
{
  projPJ *v = (projPJ*)luaL_checkudata(L, 1, PROJECTION_METATABLE_NAME);
  if (pj_is_latlong(*v))
    lua_pushboolean(L, 1);
  else
    lua_pushboolean(L, 0);
  return 1;
}


static int luaproj_get_def(lua_State *L)
{
  projPJ *v = (projPJ*)luaL_checkudata(L, 1, PROJECTION_METATABLE_NAME);
  int options = luaL_checkinteger(L, 2);
  const char *def = pj_get_def(*v, options);
  lua_pushstring(L, def);
  return 1;
}


static int luaproj_error_string(lua_State *L)
{
  if (!(lua_isnumber(L, 1) || lua_isnil(L, 1) || lua_gettop(L) == 0))
    luaL_argerror(L, 1, "expected an error code or nil");
  int code;
  if (lua_isnumber(L, 1))
    code = lua_tointeger(L, 1);
  else
    code = *pj_get_errno_ref();

  lua_pushstring(L, pj_strerrno(code));
  return 1;
}


static int luaproj_transform(lua_State *L)
{
  projPJ *input = (projPJ*)luaL_checkudata(L, 1, PROJECTION_METATABLE_NAME);
  projPJ *output = (projPJ*)luaL_checkudata(L, 2, PROJECTION_METATABLE_NAME);
  double x = luaL_checknumber(L, 3);
  double y = luaL_checknumber(L, 4);
  int code = pj_transform(*input, *output, 1, 1, &x, &y, 0);
  lua_pushinteger(L, code);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  return 3;
}



/*--------------------------------------------------------------------------*/

LUALIB_API int luaopen_proj_core(lua_State *L)
{
  luaL_newmetatable(L, PROJECTION_METATABLE_NAME);
  lua_pushcfunction(L, luaproj_free);
  lua_setfield(L, -2, "__gc");


  lua_newtable(L);
  lua_pushcfunction(L, luaproj_init);
  lua_setfield(L, -2, "pj_init_plus");
  lua_pushcfunction(L, luaproj_is_latlong);
  lua_setfield(L, -2, "pj_is_latlong");
  lua_pushcfunction(L, luaproj_get_def);
  lua_setfield(L, -2, "pj_get_def");
  lua_pushcfunction(L, luaproj_error_string);
  lua_setfield(L, -2, "pj_error_string");
  lua_pushcfunction(L, luaproj_transform);
  lua_setfield(L, -2, "pj_transform");

  return 1;
}


/*--------------------------------------------------------------------------*/

