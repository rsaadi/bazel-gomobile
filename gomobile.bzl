load("@io_bazel_rules_go//go:def.bzl", "go_path")
load("@io_bazel_rules_go//go:def.bzl", "GoLibrary", "GoPath", "go_context")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

def _gomobile_binary_impl(ctx):
    go = go_context(ctx)
    gopath = ctx.attr.go_path[GoPath]

    print("android_home conf =", ctx.configuration.default_shell_env)
    env = dicts.add(go.env, {
        "CGO_ENABLED": "1",
        "GOCACHE": "${PWD}",
        "GO111MODULE": "off",
        "GODEBUG": "embedfollowsymlinks=1",
        "GOPATH": paths.join("${PWD}", gopath.gopath_file.dirname),
        "GOROOT": paths.join("${PWD}", go.sdk_root.dirname),
        "PATH": ":".join([
            paths.join("${PWD}", paths.join(go.sdk_root.dirname, "bin")),
            "${GOPATH}/src",
            paths.join("${PWD}", ctx.executable._gomobile.dirname),
            paths.join("${PWD}", ctx.executable._gobind.dirname),
            "${PATH}",
        ]),
    })

    target = ctx.attr.target

    packages = [d[GoLibrary].importpath for d in ctx.attr.deps]
    packages += ctx.attr.extrapackages
    iosOutput = False
    androidOutput = False

    output = ""
    androidParams = []
    flags = ctx.attr.flags

    if target == "android":
        output = ctx.actions.declare_file(ctx.attr.name + ".aar")
        if ctx.attr.bootclasspath:
            androidParams.append("-bootclasspath " + ctx.attr.bootclasspath)
        if ctx.attr.classpath:
            androidParams.append("-classpath " + ctx.attr.classpath)
    else:
        output = ctx.actions.declare_directory(ctx.attr.name + ".xcframework")

    commands = [
        " && ".join(["export %s=\"%s\"" % (k, v) for k, v in env.items()]),
        ctx.executable._gomobile.path + " bind -target " + target + " ".join(androidParams) + " " + " ".join(flags) + " -o " + output.path + " " + " ".join(packages),
    ]

    ctx.actions.run_shell(
        inputs = ctx.attr.go_path.files,
        outputs = [output],
        command = " && ".join(commands),
        arguments = [],
        progress_message = "Generating mobile archive " + output.path + " ...",
        mnemonic = "bind",
        use_default_shell_env = True,
        tools = depset(transitive = [depset([
            go.go,
            ctx.executable._gomobile,
            ctx.executable._gobind,
            ctx.executable._zipper,
        ]), go.sdk.tools, go.sdk.srcs, go.sdk.headers]),
    )

    return [DefaultInfo(files = depset([output]))]

_gomobile_library = rule(
    implementation = _gomobile_binary_impl,
    attrs = {
        "target": attr.string(
            mandatory = True,
            values = ["android", "ios", "iossimulator", "macos", "maccatalyst"],
            default = "ios",
        ),
        "bootclasspath": attr.string(
            mandatory = False,
        ),
        "classpath": attr.string(
            mandatory = False,
        ),
        "flags": attr.string_list(
            mandatory = False,
            default = [],
        ),
        "deps": attr.label_list(
            mandatory = True,
            providers = [GoLibrary],
        ),
        "extrapackages": attr.string_list(
            mandatory = False,
            default = [],
        ),
        "go_path": attr.label(
            mandatory = True,
            providers = [GoPath],
        ),
        "_gomobile": attr.label(
            default = Label("@org_golang_x_mobile//cmd/gomobile:gomobile"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_gobind": attr.label(
            default = Label("@org_golang_x_mobile//cmd/gobind:gobind"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_bind": attr.label(
            default = Label("@org_golang_x_mobile//bind"),
            allow_single_file = True,
            cfg = "target",
        ),
        "_zipper": attr.label(
            default = Label("@bazel_tools//tools/zip:zipper"),
            allow_single_file = True,
            executable = True,
            cfg = "exec",
        ),
        "_androidsdk": attr.label(
            default = "@androidsdk//:sdk",
        ),
    },
    output_to_genfiles = True,
    toolchains = ["@io_bazel_rules_go//go:toolchain"],
)

def _go_path(name, deps = [GoLibrary]):
    gopath_lib = "gopath_libs" + name

    go_path(
        name = gopath_lib,
        mode = "link",
        include_pkg = True,
        include_transitive = True,
        deps = deps + [
            "@org_golang_x_mobile//bind",
            "@org_golang_x_mobile//bind/objc",
            "@org_golang_x_mobile//bind/java",
            "@org_golang_x_mobile//bind/seq",
        ],
        tags = ["manual"],
    )

    return gopath_lib

def gomobile_mac_library(
        name,
        catalyst = False,
        flags = [],
        deps = [GoLibrary],
        extrapackages = []):
    target = "macos"
    if catalyst:
        target = "maccatalyst"

    _gomobile_library(
        name = name,
        target = target,
        flags = flags,
        deps = deps,
        extrapackages = extrapackages,
        go_path = _go_path(name, deps),
    )

def gomobile_ios_library(
        name,
        sim_only = False,
        flags = [],
        deps = [GoLibrary],
        extrapackages = []):
    target = "ios"
    if sim_only:
        target = "iossimulator"

    _gomobile_library(
        name = name,
        target = target,
        flags = flags,
        deps = deps,
        extrapackages = extrapackages,
        go_path = _go_path(name, deps),
    )

def gomobile_android_library(
        name,
        target = "android",
        bootclasspath = "",
        classpath = "",
        flags = [],
        deps = [GoLibrary],
        extrapackages = []):
    _gomobile_library(
        name = name,
        target = target,
        bootclasspath = bootclasspath,
        classpath = classpath,
        flags = flags,
        deps = deps,
        extrapackages = extrapackages,
        go_path = _go_path(name, deps),
    )
