# AGENTS.md

## 协作约定

1. 这是 `TKMacros` 项目，已有宏和新增宏要共存；不要因为新增一个宏而删除已有的 `LaunchItemRegister` 相关源码、测试或注册项。
2. 修改 `Sources/TKMacrosExecutable` 下的宏实现后，必须运行 `./build.sh`，并确认 `Prebuilt/TKMacrosExecutable` 已刷新。
3. `TKMacrosPlugin` 的 `providingMacros` 必须包含所有对外暴露的宏实现。
4. `Sources/TKMacros` 放宏声明和使用方可见的类型；`Sources/TKMacrosExecutable` 放编译器插件实现。
5. CocoaPods 发布前检查 `TKMacros.podspec` 的版本、`Prebuilt/TKMacrosExecutable`、git tag 三者一致。
6. 私有 specs 的固定 git 地址是 `git@github.com:TokenTeamiOS/TKSpecs.git`；本地 CocoaPods repo 名只是本机别名，不要假设一定叫 `tokenteamios-tkspecs`。
7. 如果本地还没有 specs repo，可先添加：

```sh
pod repo add tkspecs git@github.com:TokenTeamiOS/TKSpecs.git
```

9. 发布私有 specs 使用本机实际 repo 名，例如：

```sh
pod repo push tkspecs TKMacros.podspec --allow-warnings
```

## 当前宏

- `LaunchItemRegister`：注册启动任务到 `__DATA_CONST,__tk_launch_item`。
- `DebugMenuEntry`：注册调试菜单项到 `__DATA_CONST,__tk_debug_menu`。
