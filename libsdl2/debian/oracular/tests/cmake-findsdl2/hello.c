/*
 * Copyright 2019 Collabora Ltd.
 * SPDX-License-Identifier: Zlib
 * (see "zlib/libpng" in debian/copyright)
 */

#include <SDL.h>

int
main (int argc, char **argv)
{
  if (SDL_Init(0) != 0) {
      SDL_Log("SDL_Init: %s", SDL_GetError());
      return 1;
  }

  SDL_Log("Hello, world!");
  SDL_Quit();
  return 0;
}
