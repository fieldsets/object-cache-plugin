



## Installation

`git clone --recurse-submodules https://github.com/fieldsets/object-cache`

Add to `/plugins/docker-compose.envars.yml`
```
include:
  - path: ${FIELDSETS_PLUGIN_PATH:-./plugins/}object-cache-plugin/config/docker/docker-compose.envvars.yml
    project_directory: ${FIELDSETS_PLUGIN_PATH:-./plugins/}object-cache-plugin/
```

Add to `/plugins/docker-compose.volumes.yml`
```
include:
  - path: ${FIELDSETS_PLUGINS_PATH:-./plugins/}object-cache-plugin/config/docker/docker-compose.volumes.yml
    project_directory: ${FIELDSETS_PLUGINS_PATH:-./plugins/}object-cache-plugin/
```
