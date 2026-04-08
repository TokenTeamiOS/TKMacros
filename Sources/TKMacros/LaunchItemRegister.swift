import Foundation

// MARK: - LaunchLevel

/// Defines the execution phase for registered launch items.
///
/// Phases execute in order:
/// - `head`: Critical initialization (crash reporting, logging) - main thread
/// - `main`: Core services setup - main thread
/// - `mainAsync`: Core services setup - background thread
/// - `sub`: Secondary services (triggered in didBecomeActive) - main thread
/// - `idle`: Deferred tasks (RunLoop idle) - main thread
/// - `idleAsync`: Deferred tasks (RunLoop idle) - background thread
/// - `firstScreenIdle`: Triggered via RunLoop observer when user enters home screen - main thread
///   - If logged in: triggers when splash screen is removed
///   - If not logged in: triggers after login completes and login page is dismissed
public enum LaunchLevel: Int32, Sendable {
    case head = 0
    case main = 1
    case mainAsync = 2
    case sub = 3
    case idle = 4
    case idleAsync = 5
    case firstScreenIdle = 6
}

// MARK: - LaunchSectionItem

/// Function pointer type for getting the LaunchItem type.
public typealias LaunchItemGetter = @convention(c) () -> UnsafeRawPointer

/// A tuple stored in the `__DATA_CONST,__tk_launch_item` Mach-O section.
///
/// This structure is populated at compile time by the @LaunchItemRegister macro
/// and read at runtime by the section scanner.
///
/// ## Memory Layout (16 bytes on 64-bit)
/// - `getter`: 8 bytes - Function pointer that returns the LaunchItem.Type
/// - `level`: 4 bytes - The launch phase (LaunchLevel raw value)
/// - `priority`: 4 bytes - Task priority within the phase
public typealias LaunchSectionItem = (
    getter: LaunchItemGetter,
    level: Int32,
    priority: Int32
)

// MARK: - LaunchItemRegister Macro

/// Registers a class for launch initialization with a specific phase and priority.
///
/// Use this macro to decorate a class that inherits from `LaunchItem`.
/// It will generate the required property overrides and register
/// the type in a Mach-O section for runtime discovery.
///
/// ## Basic Usage
///
/// ```swift
/// @LaunchItemRegister(level: .main)
/// final class NetworkSetupTask: LaunchItem {
///     override class func launch(with context: LaunchContext) {
///         // Initialize networking layer
///     }
/// }
/// ```
///
/// ## With Priority
///
/// ```swift
/// @LaunchItemRegister(level: .head, priority: 100)
/// final class CrashReportingTask: LaunchItem {
///     override class func launch(with context: LaunchContext) {
///         // Initialize crash reporting (runs first in head phase)
///     }
/// }
/// ```
///
/// ## Generated Code
///
/// The macro generates the following members:
/// - `identifier`: Returns the class name
/// - `priority`: Returns the priority value
/// - `levelRawValue`: Returns the LaunchLevel raw value
/// - `__tk_launch_item_entry`: Static variable stored in `__DATA_CONST,__tk_launch_item` section
///
/// And a peer function:
/// - `__tk_launch_item_getType_<TypeName>`: Global function that returns the type metadata
///
/// - Note: The class must inherit from `LaunchItem` and override `launch(with:)`.
///
/// - Parameters:
///   - level: The launch phase for this task.
///   - priority: Priority within the phase (higher executes first, default: 0).
@attached(member, names: named(identifier), named(priority), named(levelRawValue), named(__tk_launch_item_entry))
@attached(peer, names: prefixed(__tk_launch_item_getType_))
public macro LaunchItemRegister(
    level: LaunchLevel,
    priority: Int = 0
) = #externalMacro(module: "TKMacrosExecutable", type: "LaunchItemRegisterMacro")
