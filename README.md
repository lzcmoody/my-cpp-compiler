The project aim to help create c++ compile docker images which based on gcc:10.2.
Docker image my_cpp_compiler encapsulated for testing or self-learning.

# Precondition
Based on LINUX platform, docker is mandatory.

# Usage
`sh build_image.sh`

`docker images | grep my_cpp_compiler`

`docker run -tid -v HOST_PATH:CONTAINER_PATH my_cpp_compiler:v1.0 /bin/bash`

*Note*: replace **HOST_PATH** and **CONTAINER_PATH** to the real path.

# Configuration: conf.ini
| key                 | description               | example                    |
| :-------------------| :-------------------------| :--------------------------|
| default_package_dir | package downloaded folder | *packages*                 | 
| package_pull_policy | if_not_present / always   | *if_not_present*           |
| base_image          | docker base image         | *gcc:10.2*                 |
| image_name          | target image name         | *my_cpp_compiler*          |
| image_version       | target image version      | *v1.0*                     |
| [dependence]        | package urls or names     | *pkg-config-0.29.2.tar.gz* |
| [install]           | installation scripts      | *install_pkg_config.sh*    |

# Components
Here's components installed inside my_cpp_compiler:v1.0:
* gcc:v10.2
* cmake:v3.23.2
* pkg-config:0.29.2
* boost:1.79.0

# Extension
If the components didn't suffice your requirement, you can choose upgrade or extend it.
1) Edit conf.ini, add new item (component name or url) to [dependence]; Add new item (installation script) to [install].
2) Define new component installation script to **scripts** folder, eg: install_<EXTENDED_COMPONENT>.sh
3) Needn't modify scripts/entrypoints.sh and Dockerfile.
4) sh build_images.sh

# Limitation
* without guarantee components installed in order.
* all packages and scripts must under my_cpp_compiler folder.

# Thirdparty
https://github.com/nanigashi-uji/parse_ini_sh
