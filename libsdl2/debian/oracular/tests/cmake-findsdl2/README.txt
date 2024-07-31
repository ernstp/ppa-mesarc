THIS IS NOT THE RECOMMENDED WAY TO USE SDL2 FROM CMAKE

Since SDL 2.0.6, the recommended way to link to a system copy of SDL2
from a CMake project is to behave like debian/tests/cmake-example - use
find_package(SDL2) without a FindSDL2 macro. However, not all upstream
projects that build using CMake have caught up with this yet.

This specific implementation was taken from openjk,
but it's regularly copied around, and can be found
in hedgewars, spring and many other packages:
https://codesearch.debian.net/search?q=Other+versions+link+to+-lSDL2main&literal=1

Inclusion of a vaguely similar file in CMake was rejected in
<https://github.com/Kitware/CMake/pull/149>.

Bug-Debian: https://bugs.debian.org/951087
