



## Installation

`git clone --recurse-submodules https://github.com/fieldsets/object-cache`

Add to `/plugins/docker-compose.yml`
```
version: '3.7'

include:
  - path: ${FIELDSETS_PLUGIN_PATH:-./plugins/}object-cache/docker-compose.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}object-cache/
```
