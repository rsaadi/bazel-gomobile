# bazel-gomobile

## Getting started

```
bazel_dep(name = "rules_go", version = "0.59.0", repo_name = "io_bazel_rules_go")
bazel_dep(name = "bazel_skylib", version = "1.8.1")
bazel_dep(name = "gazelle", version = "0.47.0", repo_name = "bazel_gazelle")

bazel_dep(name = "gomobile_bind", version = "2.0.0")
git_override(
    module_name = "gomobile_bind",
    remote = "https://github.com/rsaadi/bazel-gomobile.git",
    tag = "v2.0.0",
)

go_deps = use_extension("@bazel_gazelle//:extensions.bzl", "go_deps")
go_deps.module(
    path = "golang.org/x/mobile",
    sum = "h1:uT3oYo9M38vJa7JpT4kCie2lJwOpoUrx7FvV0H7kXSc=",
    version = "v0.0.0-20260217195705-b56b3793a9c4",
)

# Apply patchs from gomobile_bind repo
go_deps.module_override(
    patch_strip = 1,
    patches = [
        "@gomobile_bind//:0001-fix-go_repository-bazel-BUILD-files.patch",
        "@gomobile_bind//:0002-improve_enum_array_go_mobile.patch",
    ],
    path = "golang.org/x/mobile",
)

go_deps.module(
    path = "golang.org/x/tools",
    sum = "h1:DVSRzp7FwePZW356yEAChSdNcQo6Nsp+fex1SUW09lE=",
    version = "v0.37.0",
)
go_deps.module(
    path = "golang.org/x/sync",
    sum = "h1:DVSRzp7FwePZW356yEAChSdNcQo6Nsp+fex1SUW09lE=",
    version = "v0.17.0",
)
go_deps.module(
    path = "golang.org/x/mod",
    sum = "h1:gQBtGhjxykdjY9YhZpSlZIsbnaE2+PgjfLWUQTnoZ1U=",
    version = "v0.28.0",
)
use_repo(
    go_deps,
    "org_golang_x_mobile",
    "org_golang_x_mod",
    "org_golang_x_sync",
    "org_golang_x_tools",
)
```


