import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TKMacrosExecutable)
    import TKMacrosExecutable
#endif

final class LaunchItemRegisterMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "LaunchItemRegister": LaunchItemRegisterMacro.self
    ]

    func testBasicExpansion() throws {
        assertMacroExpansion(
            """
            @LaunchItemRegister(level: .main)
            final class NetworkTask: LaunchItem {
                override class func launch(with context: LaunchContext) {
                }
            }
            """,
            expandedSource: """
                final class NetworkTask: LaunchItem {
                    override class func launch(with context: LaunchContext) {
                    }

                    override public class var identifier: String {
                        "NetworkTask"
                    }

                    override public class var priority: Int {
                        0
                    }

                    override public class var levelRawValue: Int32 {
                        1
                    }

                    @section("__DATA_CONST,__tk_launch_item")
                    @used
                    private static let __tk_launch_item_entry: LaunchSectionItem = (
                        getter: __tk_launch_item_getType_NetworkTask,
                        level: 1,
                        priority: 0
                    )
                }

                @_cdecl("__tk_launch_item_getType_NetworkTask")
                public func __tk_launch_item_getType_NetworkTask() -> UnsafeRawPointer {
                    unsafeBitCast(NetworkTask.self as Any.Type, to: UnsafeRawPointer.self)
                }
                """,
            macros: testMacros
        )
    }

    func testExpansionWithPriority() throws {
        assertMacroExpansion(
            """
            @LaunchItemRegister(level: .head, priority: 100)
            final class CrashReportingTask: LaunchItem {
                override class func launch(with context: LaunchContext) {
                }
            }
            """,
            expandedSource: """
                final class CrashReportingTask: LaunchItem {
                    override class func launch(with context: LaunchContext) {
                    }

                    override public class var identifier: String {
                        "CrashReportingTask"
                    }

                    override public class var priority: Int {
                        100
                    }

                    override public class var levelRawValue: Int32 {
                        0
                    }

                    @section("__DATA_CONST,__tk_launch_item")
                    @used
                    private static let __tk_launch_item_entry: LaunchSectionItem = (
                        getter: __tk_launch_item_getType_CrashReportingTask,
                        level: 0,
                        priority: 100
                    )
                }

                @_cdecl("__tk_launch_item_getType_CrashReportingTask")
                public func __tk_launch_item_getType_CrashReportingTask() -> UnsafeRawPointer {
                    unsafeBitCast(CrashReportingTask.self as Any.Type, to: UnsafeRawPointer.self)
                }
                """,
            macros: testMacros
        )
    }

    func testAllLevels() throws {
        assertMacroExpansion(
            """
            @LaunchItemRegister(level: .idle)
            class IdleTask: LaunchItem {
                override class func launch(with context: LaunchContext) {}
            }
            """,
            expandedSource: """
                class IdleTask: LaunchItem {
                    override class func launch(with context: LaunchContext) {}

                    override public class var identifier: String {
                        "IdleTask"
                    }

                    override public class var priority: Int {
                        0
                    }

                    override public class var levelRawValue: Int32 {
                        4
                    }

                    @section("__DATA_CONST,__tk_launch_item")
                    @used
                    private static let __tk_launch_item_entry: LaunchSectionItem = (
                        getter: __tk_launch_item_getType_IdleTask,
                        level: 4,
                        priority: 0
                    )
                }

                @_cdecl("__tk_launch_item_getType_IdleTask")
                public func __tk_launch_item_getType_IdleTask() -> UnsafeRawPointer {
                    unsafeBitCast(IdleTask.self as Any.Type, to: UnsafeRawPointer.self)
                }
                """,
            macros: testMacros
        )
    }

    func testErrorOnEnum() throws {
        // LaunchItemRegisterMacro is both MemberMacro and PeerMacro,
        // so it emits the error twice (once for each conformance)
        assertMacroExpansion(
            """
            @LaunchItemRegister(level: .main)
            enum MyEnum {}
            """,
            expandedSource: """
                enum MyEnum {}
                """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@LaunchItemRegister can only be applied to a class or struct.",
                    line: 1, column: 1),
                DiagnosticSpec(
                    message: "@LaunchItemRegister can only be applied to a class or struct.",
                    line: 1, column: 1),
            ],
            macros: testMacros
        )
    }

    func testInvalidLevelCase() throws {
        // PeerMacro still generates the getter function even when MemberMacro fails
        assertMacroExpansion(
            """
            @LaunchItemRegister(level: .unknown)
            class MyTask: LaunchItem {}
            """,
            expandedSource: """
                class MyTask: LaunchItem {}

                @_cdecl("__tk_launch_item_getType_MyTask")
                public func __tk_launch_item_getType_MyTask() -> UnsafeRawPointer {
                    unsafeBitCast(MyTask.self as Any.Type, to: UnsafeRawPointer.self)
                }
                """,
            diagnostics: [
                DiagnosticSpec(
                    message:
                        "@LaunchItemRegister: unknown level case 'unknown'. Valid: head, main, mainAsync, sub, idle, idleAsync, firstScreenIdle.",
                    line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}
