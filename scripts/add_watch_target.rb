require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if target already exists
if project.targets.find { |t| t.name == 'WatchCompanion' }
  puts "WatchCompanion target already exists."
  exit
end

# Find the iOS target to link against
ios_target = project.targets.find { |t| t.name == 'Runner' }
unless ios_target
  puts "Runner target not found."
  exit 1
end

# Add Watch App target
watch_target = project.new_target(:watch_app, 'WatchCompanion', :watchos, '10.0', nil, :swift)
watch_target.product_name = 'WatchCompanion'
watch_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'art.dart.clawfree.watch'
  config.build_settings['SDKROOT'] = 'watchos'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '4' # Watch
  config.build_settings['WATCHOS_DEPLOYMENT_TARGET'] = '10.0'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_FILE'] = 'WatchCompanion/Info.plist'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# Create group and add files
watch_group = project.main_group.find_subpath('WatchCompanion', true)
watch_group.set_source_tree('<group>')

Dir.glob('ios/WatchCompanion/*.swift').each do |file_path|
  file_ref = watch_group.new_file(File.basename(file_path))
  watch_target.add_file_references([file_ref])
end

# Add dependency: iOS app depends on Watch app (watchOS 7+, standalone Watch app)
ios_target.add_dependency(watch_target)

# Add "Embed Watch Content" copy files build phase
embed_phase = ios_target.new_copy_files_build_phase('Embed Watch Content')
embed_phase.dst_subfolder_spec = '16'  # Products Directory
embed_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'

build_file = embed_phase.add_file_reference(watch_target.product_reference)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Create scheme
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(watch_target)
scheme.save_as(project_path, 'WatchCompanion')

project.save
puts "Successfully added WatchCompanion target and scheme."
