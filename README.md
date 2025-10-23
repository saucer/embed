<hr>

<div align="center"> 
    <img src="https://github.com/saucer/saucer.github.io/blob/v7/src/assets/logo-alt.svg?raw=true" height="312" />
</div>

<p align="center"> 
    Embedding utility for <a href="https://github.com/saucer/saucer">saucer</a>
</p>

---

## 📦 Installation

* Using [CPM](https://github.com/cpm-cmake/CPM.cmake)
  ```cmake
  CPMFindPackage(
    NAME           saucer-embed
    VERSION        1.0.0
    GIT_REPOSITORY "https://github.com/saucer/embed"
  )
  ```

* Using FetchContent
  ```cmake
  include(FetchContent)

  FetchContent_Declare(saucer-embed GIT_REPOSITORY "https://github.com/saucer/embed" GIT_TAG v1.0.0)
  FetchContent_MakeAvailable(saucer-embed)
  ```

