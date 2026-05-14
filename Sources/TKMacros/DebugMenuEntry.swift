import Foundation

@attached(member, names: named(_tk_debug_menu_item))
@attached(peer, names: prefixed(__tk_debug_menu_item_getter_))
public macro DebugMenuEntry() = #externalMacro(module: "TKMacrosExecutable", type: "DebugMenuEntryMacro")
