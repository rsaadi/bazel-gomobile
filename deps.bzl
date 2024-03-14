load("@bazel_gazelle//:deps.bzl", "go_repository")

def gobind_dependencies(gomobile_repo_name):
    go_repository(
        name = "org_golang_x_gomobile",
        importpath = "golang.org/x/mobile",
        sum = "h1:iZzqyDd8gFkJZpsJNzveyScRBcQlsveheh6Q77LzhPY=",
        version = "v0.0.0-20240213143359-d1f7d3436075",
        patch_tool = "git",
        patch_args = ["apply"],
        patches = [
            gomobile_repo_name + "//:0001-fix-go_repository-bazel-BUILD-files.patch",
            gomobile_repo_name + "//:0002-add-support-for-go-enum-to-ios.patch",
            gomobile_repo_name + "//:0003-add-support-for-array-to-ios.patch",
            gomobile_repo_name + "//:0004-Add-support-for-enum-and-array-for-android.patch",
            gomobile_repo_name + "//:0005-Generate-an-XCode-xcFramework-out-of-lib.patch",
        ],
    )
