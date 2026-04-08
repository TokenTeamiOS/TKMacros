# This script injects required Swift flags into targets that depend on TKMacros.
# It supports both direct and transitive (indirect) dependencies.
#
# Usage in Podfile:
#
# require_relative 'Scripts/tk_swift_flags'
#
# post_install do |installer|
#   inject_tk_swift_flags_if_needed(installer)
# end

require 'set'

def inject_tk_swift_flags_if_needed(installer)
  flags_to_inject = '-load-plugin-executable ${PODS_ROOT}/TKMacros/Prebuilt/TKMacrosExecutable#TKMacrosExecutable -enable-experimental-feature SymbolLinkageMarkers'
  dependency_name = 'TKMacros'

  # Build a name-to-target map for resolving transitive dependencies
  target_map = {}
  installer.pods_project.targets.each do |t|
    target_map[t.name] = t
  end

  # Handle both pods_project and generated_projects (when using generate_multiple_pod_projects)
  all_projects = [installer.pods_project]
  all_projects += installer.generated_projects if installer.respond_to?(:generated_projects)

  all_projects.each do |project|
    project.targets.each do |target|
      # Skip aggregate targets or targets starting with 'Pods-'
      next if target.name.start_with?('Pods-')

      # Check if this target depends on TKMacros (directly or transitively)
      next unless depends_on_transitively?(target, dependency_name, target_map)

      puts "[TK_SWIFT_FLAGS] Injecting flags for target: #{target.name}"
      target.build_configurations.each do |config|
        current_flags = config.build_settings['OTHER_SWIFT_FLAGS'] || '$(inherited)'

        # Avoid duplicate injection
        next if current_flags.include?('TKMacrosExecutable')

        # Append the flags
        new_flags = "#{current_flags} #{flags_to_inject}"
        config.build_settings['OTHER_SWIFT_FLAGS'] = new_flags
      end
    end
  end
end

# Recursively checks whether +target+ depends on +dependency_name+,
# either directly or through any of its transitive dependencies.
#
# +target_map+ is a Hash { target_name => PBXNativeTarget } used to resolve
# dependencies whose +dep.target+ reference is nil.
#
# +visited+ prevents infinite recursion in the presence of circular dependencies.
def depends_on_transitively?(target, dependency_name, target_map, visited = Set.new)
  return false if visited.include?(target.name)

  visited.add(target.name)

  target.dependencies.any? do |dep|
    dep_name = dep.name || (dep.target && dep.target.name)

    # Direct match
    next true if dep_name == dependency_name

    # Resolve the dependency target and check recursively
    dep_target = dep.target || target_map[dep_name]
    next false unless dep_target

    depends_on_transitively?(dep_target, dependency_name, target_map, visited)
  end
end
