require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find or create Watch App target
watch_target = project.targets.find { |t| t.name == 'WatchCompanion' }
unless watch_target
  watch_target = project.new_target(:watch2_app, 'WatchCompanion', :watchos, '10.0', nil, :swift)
  watch_target.product_name = 'WatchCompanion'
end

watch_target.product_type = 'com.apple.product-type.application'

watch_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_NAME'] = 'WatchCompanion'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'art.dart.clawfree.watch'
  config.build_settings['SDKROOT'] = 'watchos'
  config.build_settings['SUPPORTED_PLATFORMS'] = 'watchos watchsimulator'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '4' # Watch
  config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_FILE'] = 'WatchCompanion/Info.plist'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# Update group path and re-add files
watch_group = project.main_group.find_subpath('WatchCompanion', true)
watch_group.path = 'WatchCompanion'
watch_group.set_source_tree('<group>')

# Clear existing references to avoid duplicates or wrong paths
watch_target.source_build_phase.files_references.each do |ref|
  watch_target.source_build_phase.remove_file_reference(ref)
end
watch_target.resources_build_phase.files_references.each do |ref|
  watch_target.resources_build_phase.remove_file_reference(ref)
end

Dir.glob('ios/WatchCompanion/*.swift').each do |file_path|
  file_name = File.basename(file_path)
  # Remove from group if exists to re-add with correct path
  if existing_ref = watch_group.find_subpath(file_name)
    existing_ref.remove_from_project
  end
  file_ref = watch_group.new_file(file_name)
  watch_target.add_file_references([file_ref])
end

# Add Assets.xcassets
assets_name = 'Assets.xcassets'
if existing_assets = watch_group.find_subpath(assets_name)
  existing_assets.remove_from_project
end
assets_ref = watch_group.new_file(assets_name)
watch_target.add_resources([assets_ref])

# Ensure scheme exists and is correctly configured
scheme_path = Xcodeproj::XCScheme.shared_data_dir(project_path) + 'WatchCompanion.xcscheme'
unless File.exist?(scheme_path)
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(watch_target)
  scheme.save_as(project_path, 'WatchCompanion')
end

project.save
puts "Successfully updated WatchCompanion target and scheme."
