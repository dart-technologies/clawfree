#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Check if watch target already exists
if project.targets.any? { |t| t.name == 'ClawfreeWatch' }
  puts "ClawfreeWatch target already exists, skipping."
  exit 0
end

# Create watchOS app target
watch_target = project.new_target(:application, 'ClawfreeWatch', :watchos, '8.0')

watch_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.rollbytes.clawfree.watchkitapp'
  s['DEVELOPMENT_TEAM'] = '3HUWM4L2MV'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['SWIFT_VERSION'] = '5.0'
  s['INFOPLIST_FILE'] = '$(SRCROOT)/ClawfreeWatch/Info.plist'
  s['WATCHOS_DEPLOYMENT_TARGET'] = '8.0'
  s['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['TARGETED_DEVICE_FAMILY'] = '4'  # Watch
  s['SDKROOT'] = 'watchos'
  s['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
end

# Add source group and files
watch_group = project.main_group.new_group('ClawfreeWatch', 'ClawfreeWatch')

swift_files = Dir.glob('ClawfreeWatch/*.swift')
swift_files.each do |f|
  file_ref = watch_group.new_file(File.basename(f))
  watch_target.source_build_phase.add_file_reference(file_ref)
end

# Add Assets.xcassets
assets_ref = watch_group.new_file('Assets.xcassets')
watch_target.resources_build_phase.add_file_reference(assets_ref)

# Add "Embed Watch Content" copy phase to Runner
runner_target = project.targets.find { |t| t.name == 'Runner' }
if runner_target
  embed_phase = runner_target.new_copy_files_build_phase('Embed Watch Content')
  embed_phase.dst_subfolder_spec = '16'  # Products Directory
  embed_phase.dst_path = '$(CONTENTS_FOLDER_PATH)/Watch'

  # Add watch app product reference
  embed_phase.add_file_reference(watch_target.product_reference)
  embed_phase.files.last.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

  # Add target dependency
  runner_target.add_dependency(watch_target)
end

# Create scheme for ClawfreeWatch
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(watch_target)
scheme.set_launch_target(watch_target)
scheme.save_as(project_path, 'ClawfreeWatch')

project.save
puts "✅ ClawfreeWatch target added successfully!"
puts "   Swift files: #{swift_files.map { |f| File.basename(f) }.join(', ')}"
