load("@bazel_gazelle//:deps.bzl", "go_repository")

def gobind_dependencies(gomobile_repo_name):
    go_repository(
        name = "org_golang_x_gomobile",
        importpath = "golang.org/x/mobile",
        sum = "h1:Gk61ECugwEHL6IiyyNLXNzmu8XslmRP2dS0xjIYhbb4=",
        version = "v0.0.0-20230301163155-e0f57694e12c",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [gomobile_repo_name + "//:0001-fix-go_repository-bazel-BUILD-files.patch",
                   gomobile_repo_name + "//:0002-add-support-for-go-enum-to-ios.patch",
                   gomobile_repo_name + "//:0003-add-support-for-array-to-ios.patch"],
    )
