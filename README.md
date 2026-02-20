# bazel-gomobile

Bazel rules for [Go Mobile](https://github.com/golang/mobile), enabling reproducible `gomobile bind` builds for iOS, macOS, and Android — with patches that extend the upstream `gobind` code generator to support exporting Go arrays and enums to host languages.

## Rules

| Rule | Output | Description |
|------|--------|-------------|
| `gomobile_ios_library` | `.xcframework` | Binds a Go package for iOS (device + simulator) |
| `gomobile_mac_library` | `.xcframework` | Binds a Go package for macOS or Mac Catalyst |
| `gomobile_android_library` | `.aar` | Binds a Go package for Android |

---

## Installation

Add the following to your `MODULE.bazel`:

```starlark
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

# Apply patches from the gomobile_bind repo
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

---

## Usage

Load the rules in your `BUILD.bazel`:

```starlark
load("@gomobile_bind//:gomobile.bzl",
    "gomobile_ios_library",
    "gomobile_mac_library",
    "gomobile_android_library",
)
```

### iOS

```starlark
gomobile_ios_library(
    name = "mylib_ios",
    deps = ["//path/to/mypkg"],
)
```

For simulator-only builds, set `sim_only = True`:

```starlark
gomobile_ios_library(
    name = "mylib_ios_sim",
    deps = ["//path/to/mypkg"],
    sim_only = True,
)
```

### macOS

```starlark
gomobile_mac_library(
    name = "mylib_mac",
    deps = ["//path/to/go_library"],
)
```

For Mac Catalyst targets, set `catalyst = True`:

```starlark
gomobile_mac_library(
    name = "mylib_catalyst",
    deps = ["//path/to/library"],
    catalyst = True,
)
```

### Android

```starlark
gomobile_android_library(
    name = "mylib_android",
    deps = ["//path/to/library"],
)
```

With a custom Android classpath:

```starlark
gomobile_android_library(
    name = "mylib_android",
    deps = ["//path/to/library"],
    bootclasspath = "/path/to/android.jar",
    classpath = "/path/to/extras.jar",
)
```

---

## Rule Reference

### `gomobile_ios_library`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | — | Target name |
| `deps` | `list[label]` | — | Go library targets to bind (must provide `GoLibrary`) |
| `sim_only` | `bool` | `False` | If `True`, targets `iossimulator` instead of `ios` |
| `flags` | `list[string]` | `[]` | Extra flags passed to `gomobile bind` |
| `extrapackages` | `list[string]` | `[]` | Additional Go import paths to include in the binding |

### `gomobile_mac_library`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | — | Target name |
| `deps` | `list[label]` | — | Go library targets to bind (must provide `GoLibrary`) |
| `catalyst` | `bool` | `False` | If `True`, targets `maccatalyst` instead of `macos` |
| `flags` | `list[string]` | `[]` | Extra flags passed to `gomobile bind` |
| `extrapackages` | `list[string]` | `[]` | Additional Go import paths to include in the binding |

### `gomobile_android_library`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `string` | — | Target name |
| `deps` | `list[label]` | — | Go library targets to bind (must provide `GoLibrary`) |
| `bootclasspath` | `string` | `""` | Path to Android boot classpath (e.g. `android.jar`) |
| `classpath` | `string` | `""` | Path to additional classpath entries |
| `flags` | `list[string]` | `[]` | Extra flags passed to `gomobile bind` |
| `extrapackages` | `list[string]` | `[]` | Additional Go import paths to include in the binding |

---

## Patches

Two patches are applied to `golang.org/x/mobile` before the build:

### `0001-fix-go_repository-bazel-BUILD-files.patch`

Fixes the upstream Bazel `BUILD` files generated by `go_repository` so that `gomobile` and `gobind` build correctly under Bzlmod and the current `rules_go` version.

### `0002-improve_enum_array_go_mobile.patch`

Extends the `gobind` code generator to support exporting Go **arrays/slices** and **enums** (typed integer constants) across the FFI boundary. Without this patch, `gobind` silently drops these types from the generated bindings.

With the patch applied:

- Named slice types are bridged as typed array wrappers in Objective-C and Java/Kotlin
- Typed `const` blocks based on integer types are surfaced as enums or typed constants in the generated host-language code

---

## How it works

Each rule builds a `go_path` with the target package and its transitive dependencies (including `bind`, `bind/objc`, `bind/java`, and `bind/seq` from `golang.org/x/mobile`), then invokes `gomobile bind` as a Bazel action using the Go SDK toolchain.

The `gomobile` and `gobind` binaries are compiled from source via `@org_golang_x_mobile//cmd/gomobile` and `@org_golang_x_mobile//cmd/gobind`, ensuring the patched versions are always used.

---

## License

Apache 2.0 — see [LICENSE](./LICENSE).