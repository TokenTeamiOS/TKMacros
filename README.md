# TKMacros

`TKMacros` 为 TokenTeam iOS 项目提供统一的 Swift 宏声明，以及 CocoaPods 分发所需的预编译宏可执行文件。

## 宏列表

### LaunchItemRegister

`@LaunchItemRegister` 用于把启动任务注册到 `__DATA_CONST,__tk_launch_item` Mach-O section。

```swift
import TKMacros

@LaunchItemRegister(level: .main, priority: 10)
final class NetworkSetupTask: LaunchItem {
    override class func launch(with context: LaunchContext) {
        // 初始化网络层。
    }
}
```

该宏会生成：

- `identifier`
- `priority`
- `levelRawValue`
- 存入 `__DATA_CONST,__tk_launch_item` 的 section entry
- 用于运行时扫描的 C 调用 getter 函数

### DebugMenuEntry

`@DebugMenuEntry` 用于把调试菜单类型注册到 `__DATA_CONST,__tk_debug_menu` Mach-O section。

```swift
import TKDebugMenu

@DebugMenuEntry
struct NetworkDebugMenu: DebugMenuItem {
    var menu: [DebugMenuNode] {
        DebugMenuGroup("Network", identifier: "network") {
            DebugMenuAction("Clear Cache", identifier: "network.clearCache") { _ in
                URLCache.shared.removeAllCachedResponses()
            }
        }
    }
}
```

被标记的 class 或 struct 必须遵守 `DebugMenuItem`。菜单内容由 `DebugMenuItem.menu` 提供，宏只负责把类型注册到运行时可扫描的 section。

## CocoaPods 接入

从私有 specs 仓库引入 `TKMacros`：

```ruby
pod 'TKMacros'
```

podspec 会保留预编译宏可执行文件：

```sh
${PODS_ROOT}/TKMacros/Prebuilt/TKMacrosExecutable
```

并注入宏加载参数：

```sh
-load-plugin-executable ${PODS_ROOT}/TKMacros/Prebuilt/TKMacrosExecutable#TKMacrosExecutable
```

如果宿主 target 或间接依赖 `TKMacros` 的 Pod target 也需要展开宏，可以在 Podfile 中引入辅助脚本：

```ruby
require_relative 'Pods/TKMacros/Scripts/tk_swift_flags'

post_install do |installer|
  inject_tk_swift_flags_if_needed(installer)
end
```

该脚本兼容开启了 `generate_multiple_pod_projects` 的 CocoaPods 工程。

## 构建

修改 `Sources/TKMacrosExecutable` 下的宏实现后，需要重新构建预编译可执行文件：

```sh
./build.sh
```

构建产物会复制到：

```sh
Prebuilt/TKMacrosExecutable
```

## 发布

1. 更新 `TKMacros.podspec` 中的 `s.version`。
2. 运行 `./build.sh`。
3. 提交源码和 `Prebuilt/TKMacrosExecutable`。
4. 创建与 podspec 版本一致的 git tag。
5. 推送 commit 和 tag。
6. 添加或更新私有 specs 仓库。本地 repo 名可以自定义，固定的 git 地址是 `git@github.com:TokenTeamiOS/TKSpecs.git`。

```sh
pod repo add tkspecs git@github.com:TokenTeamiOS/TKSpecs.git
```

7. 发布到私有 specs 仓库：

```sh
pod repo push tkspecs TKMacros.podspec --allow-warnings
```

