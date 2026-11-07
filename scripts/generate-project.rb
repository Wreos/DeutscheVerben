require 'xcodeproj'
root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.new(File.join(root, 'DeutscheVerben.xcodeproj'))
app = project.new_target(:application, 'DeutscheVerben', :ios, '18.0')
app.product_reference.name = 'DeutscheVerben.app'
group = project.main_group.new_group('App', 'App')
Dir.glob(File.join(root, 'App', '*.swift')).sort.each { |path| app.source_build_phase.add_file_reference(group.new_file(File.basename(path))) }
app.resources_build_phase.add_file_reference(group.new_file('Assets.xcassets'))
package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
package.relative_path = 'Packages/VerbTrainerCore'
project.root_object.package_references << package
product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
product.package = package
product.product_name = 'VerbTrainerCore'
app.package_product_dependencies << product
build = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build.product_ref = product
app.frameworks_build_phase.files << build
ui = project.new_target(:ui_test_bundle, 'DeutscheVerbenUITests', :ios, '18.0')
ui.add_dependency(app)
g = project.main_group.new_group('UITests', 'UITests')
ui.source_build_phase.add_file_reference(g.new_file('FlowTests.swift'))
fixtures = project.main_group.new_group('Verification', 'Verification')
ui.resources_build_phase.add_file_reference(fixtures.new_file('synthetic-progress.json'))
[app, ui].each do |target|
 target.build_configurations.each do |config|
  config.build_settings.merge!({'SUPPORTED_PLATFORMS'=>'iphoneos iphonesimulator macosx', 'SDKROOT'=>'auto', 'IPHONEOS_DEPLOYMENT_TARGET'=>'18.0', 'MACOSX_DEPLOYMENT_TARGET'=>'15.0', 'SWIFT_VERSION'=>'6.0', 'CODE_SIGN_STYLE'=>'Automatic', 'GENERATE_INFOPLIST_FILE'=>'YES', 'TARGETED_DEVICE_FAMILY'=>'1', 'PRODUCT_BUNDLE_IDENTIFIER'=> target == app ? 'de.aleksandr.DeutscheVerben' : 'de.aleksandr.DeutscheVerben.UITests', 'ENABLE_USER_SCRIPT_SANDBOXING'=>'YES'})
 end
end
app.build_configurations.each do |c|
 c.build_settings.merge!({'INFOPLIST_KEY_CFBundleDisplayName'=>'Deutsche Verben', 'INFOPLIST_KEY_UILaunchScreen_Generation'=>'YES', 'INFOPLIST_KEY_UIApplicationSceneManifest_Generation'=>'YES', 'ASSETCATALOG_COMPILER_APPICON_NAME'=>'AppIcon', 'ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'=>'AccentColor', 'INFOPLIST_KEY_LSApplicationCategoryType'=>'public.app-category.education', 'CODE_SIGN_IDENTITY[sdk=macosx*]'=>'-', 'ENABLE_HARDENED_RUNTIME'=>'YES', 'MARKETING_VERSION'=>'1.0', 'CURRENT_PROJECT_VERSION'=>'1'})
end
ui.build_configurations.each { |c| c.build_settings['TEST_TARGET_NAME']='DeutscheVerben' }
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(ui)
scheme.set_launch_target(app)
scheme.save_as(project.path, 'DeutscheVerben', true)
