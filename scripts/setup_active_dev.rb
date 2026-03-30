#!/usr/bin/env ruby
# frozen_string_literal: true

# Run Walk Breed — Active Development セットアップ
# エクスポート済み Xcode プロジェクトに Godot プロジェクトフォルダをリンクし、
# .pck を除外して godot_path を設定する。
#
# Usage: ruby setup_active_dev.rb <xcodeproj_path> <godot_project_path>

require 'xcodeproj'
require 'pathname'

xcodeproj_path = ARGV[0] || abort("Usage: #{$0} <xcodeproj_path> <godot_project_path>")
godot_project_path = ARGV[1] || abort("Usage: #{$0} <xcodeproj_path> <godot_project_path>")

godot_project_path = File.expand_path(godot_project_path)
folder_name = File.basename(godot_project_path)

puts "=== Setting up Active Development ==="
puts "  Xcode project: #{xcodeproj_path}"
puts "  Godot project: #{godot_project_path}"

# プロジェクトを開く
project = Xcodeproj::Project.open(xcodeproj_path)
main_target = project.targets.first
abort "Error: No targets found in project" unless main_target

main_group = project.main_group

# 1. .pck ファイルを Build Phases から除外
puts "--- Removing .pck from Copy Bundle Resources ---"
main_target.build_phases.each do |phase|
  next unless phase.is_a?(Xcodeproj::Project::Object::PBXResourcesBuildPhase)

  phase.files.each do |build_file|
    ref = build_file.file_ref
    next unless ref && ref.path && ref.path.end_with?('.pck')

    puts "  Removed: #{ref.path}"
    phase.remove_build_file(build_file)
  end
end

# プロジェクトナビゲータからも .pck ファイル参照を削除
main_group.recursive_children.select { |c| c.respond_to?(:path) && c.path&.end_with?('.pck') }.each do |ref|
  puts "  Removed reference: #{ref.path}"
  ref.remove_from_project
end

# 2. 既存の同名フォルダ参照があれば削除（再セットアップ対応）
main_group.recursive_children.select { |c| c.respond_to?(:path) && c.path == folder_name }.each do |ref|
  puts "  Removed existing reference: #{ref.path}"
  ref.remove_from_project
end

# 3. Godot プロジェクトフォルダをフォルダ参照として追加
puts "--- Adding folder reference: #{folder_name} ---"
xcodeproj_dir = File.dirname(xcodeproj_path)
relative_path = Pathname.new(godot_project_path).relative_path_from(Pathname.new(xcodeproj_dir)).to_s

folder_ref = main_group.new_reference(relative_path, :project)
folder_ref.name = folder_name
folder_ref.last_known_file_type = 'folder'

# フォルダ参照を Copy Bundle Resources に追加
resources_phase = main_target.resources_build_phase
resources_phase.add_file_reference(folder_ref)
puts "  Added to Copy Bundle Resources"

# 4. Info.plist に godot_path を設定
puts "--- Setting godot_path in Info.plist ---"
export_dir = File.dirname(xcodeproj_path)

# Godot は <AppName>/<AppName>-Info.plist として出力する
app_name = File.basename(xcodeproj_path, '.xcodeproj')
plist_path = File.join(export_dir, app_name, "#{app_name}-Info.plist")

if plist_path && File.exist?(plist_path)
  # PlistBuddy で godot_path を設定
  system('/usr/libexec/PlistBuddy', '-c', "Delete :godot_path", plist_path, err: '/dev/null')
  system('/usr/libexec/PlistBuddy', '-c', "Add :godot_path string #{folder_name}", plist_path)
  puts "  Set godot_path = #{folder_name} in #{plist_path}"
else
  puts "  Warning: Info.plist not found. Set godot_path manually."
end

# 5. プロジェクトを保存
project.save
puts ""
puts "=== Active Development setup complete ==="
