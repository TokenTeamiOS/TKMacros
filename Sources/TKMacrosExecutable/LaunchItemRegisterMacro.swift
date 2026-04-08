import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct LaunchItemRegisterMacro: MemberMacro, PeerMacro {

    // MARK: - MemberMacro (generates identifier, priority, level, and section entry inside the class)

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. Validate that the macro is attached to a class or struct
        let typeName: String
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else {
            throw LaunchItemRegisterError.notAClassOrStruct
        }

        // 2. Extract arguments
        guard case .argumentList(let arguments) = node.arguments else {
            throw LaunchItemRegisterError.invalidArguments
        }

        // Extract level argument
        guard let levelArg = arguments.first(where: { $0.label?.text == "level" })?.expression
        else {
            throw LaunchItemRegisterError.invalidArguments
        }

        // Parse level to raw value
        let levelRawValue: Int32
        if let memberAccess = levelArg.as(MemberAccessExprSyntax.self) {
            let caseName = memberAccess.declName.baseName.text
            switch caseName {
            case "head": levelRawValue = 0
            case "main": levelRawValue = 1
            case "mainAsync": levelRawValue = 2
            case "sub": levelRawValue = 3
            case "idle": levelRawValue = 4
            case "idleAsync": levelRawValue = 5
            case "firstScreenIdle": levelRawValue = 6
            default:
                throw LaunchItemRegisterError.invalidLevelCase(caseName)
            }
        } else {
            throw LaunchItemRegisterError.invalidArguments
        }

        // Extract priority (default to 0)
        let priorityValue = extractPriority(from: node)

        // 3. Generate members
        // Note: We use `override class var/func` because the class inherits from LaunchItem
        let members: [DeclSyntax] = [
            """
            override public class var identifier: String { "\(raw: typeName)" }
            """,
            """
            override public class var priority: Int { \(raw: priorityValue) }
            """,
            """
            override public class var levelRawValue: Int32 { \(raw: levelRawValue) }
            """,
            // Section entry - uses tuple syntax for compile-time constant initialization
            """
            @section("__DATA_CONST,__tk_launch_item")
            @used
            private static let __tk_launch_item_entry: LaunchSectionItem = (
                getter: __tk_launch_item_getType_\(raw: typeName),
                level: \(raw: levelRawValue),
                priority: \(raw: priorityValue)
            )
            """,
        ]

        return members
    }

    // MARK: - PeerMacro (generates global getter function)

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // 1. Get the type name
        let typeName: String
        if let classDecl = declaration.as(ClassDeclSyntax.self) {
            typeName = classDecl.name.text
        } else if let structDecl = declaration.as(StructDeclSyntax.self) {
            typeName = structDecl.name.text
        } else {
            throw LaunchItemRegisterError.notAClassOrStruct
        }

        // 2. Generate a global @_cdecl function that returns the type metadata
        // NOTE: We use Any.Type for the bitcast because:
        // - Any.Type (existential metatype for Any) is exactly 1 pointer size
        // - Protocol existential metatype (any Protocol.Type) is 2 pointers (type + witness table)
        // - UnsafeRawPointer is 1 pointer, so we must use Any.Type
        let peers: [DeclSyntax] = [
            """
            @_cdecl("__tk_launch_item_getType_\(raw: typeName)")
            public func __tk_launch_item_getType_\(raw: typeName)() -> UnsafeRawPointer {
                unsafeBitCast(\(raw: typeName).self as Any.Type, to: UnsafeRawPointer.self)
            }
            """
        ]

        return peers
    }

    // MARK: - Helper

    private static func extractPriority(from node: AttributeSyntax) -> Int {
        guard case .argumentList(let arguments) = node.arguments else {
            return 0
        }

        if let priorityArg = arguments.first(where: { $0.label?.text == "priority" })?.expression {
            if let intLiteral = priorityArg.as(IntegerLiteralExprSyntax.self) {
                return Int(intLiteral.literal.text) ?? 0
            } else if let prefixExpr = priorityArg.as(PrefixOperatorExprSyntax.self),
                prefixExpr.operator.text == "-",
                let intLiteral = prefixExpr.expression.as(IntegerLiteralExprSyntax.self)
            {
                return -(Int(intLiteral.literal.text) ?? 0)
            }
        }
        return 0
    }
}

enum LaunchItemRegisterError: Error, CustomStringConvertible {
    case notAClassOrStruct
    case invalidArguments
    case invalidLevelCase(String)

    var description: String {
        switch self {
        case .notAClassOrStruct:
            return "@LaunchItemRegister can only be applied to a class or struct."
        case .invalidArguments:
            return "@LaunchItemRegister requires a 'level' argument."
        case .invalidLevelCase(let name):
            return
                "@LaunchItemRegister: unknown level case '\(name)'. Valid: head, main, mainAsync, sub, idle, idleAsync, firstScreenIdle."
        }
    }
}
