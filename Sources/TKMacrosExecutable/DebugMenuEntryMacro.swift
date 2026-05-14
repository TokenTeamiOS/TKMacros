import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct DebugMenuEntryMacro: MemberMacro, PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let typeName = try validate(declaration: declaration)

        return [
            """
            @section("__DATA_CONST,__tk_debug_menu")
            @used
            private static let _tk_debug_menu_item: @convention(c) () -> UnsafeRawPointer = __tk_debug_menu_item_getter_\(raw: typeName)
            """
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.asProtocol(DeclGroupSyntax.self) else {
            return []
        }
        let typeName = try validate(declaration: declaration)

        return [
            """
            @_cdecl("__tk_debug_menu_item_getter_\(raw: typeName)")
            func __tk_debug_menu_item_getter_\(raw: typeName)() -> UnsafeRawPointer {
                unsafeBitCast(\(raw: typeName).self, to: UnsafeRawPointer.self)
            }
            """
        ]
    }

    private static func validate(declaration: some DeclGroupSyntax) throws -> String {
        guard let typeName = declaration.debugMenuTypeName else {
            throw DebugMenuEntryMacroError.notANominalType
        }

        let conformsToDebugMenuItem = declaration.inheritanceClause?.inheritedTypes.contains { inheritedType in
            if let identifierType = inheritedType.type.as(IdentifierTypeSyntax.self) {
                return identifierType.name.text == "DebugMenuItem"
            }

            if let memberType = inheritedType.type.as(MemberTypeSyntax.self) {
                return memberType.name.text == "DebugMenuItem"
            }

            return false
        } ?? false

        if !conformsToDebugMenuItem {
            throw DebugMenuEntryMacroError.missingDebugMenuItemConformance
        }

        return typeName
    }
}

private extension DeclGroupSyntax {
    var debugMenuTypeName: String? {
        if let structDecl = self.as(StructDeclSyntax.self) {
            return structDecl.name.text
        }

        if let classDecl = self.as(ClassDeclSyntax.self) {
            return classDecl.name.text
        }

        return nil
    }
}

enum DebugMenuEntryMacroError: Error, CustomStringConvertible {
    case notANominalType
    case missingDebugMenuItemConformance

    var description: String {
        switch self {
        case .notANominalType:
            return "@DebugMenuEntry can only be applied to a struct or class."
        case .missingDebugMenuItemConformance:
            return "@DebugMenuEntry requires the type to conform to DebugMenuItem."
        }
    }
}
