import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct TKMacrosPlugin: CompilerPlugin {
    public init() {}
    public let providingMacros: [Macro.Type] = [
        LaunchItemRegisterMacro.self
    ]
}
