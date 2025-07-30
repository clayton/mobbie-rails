#!/usr/bin/env ruby

# Update all spec files to use simple_spec_helper
require 'fileutils'

Dir.glob('spec/**/*_spec.rb').each do |file|
  next if file.include?('simple_spec') || file.include?('run_all_tests')
  
  content = File.read(file)
  if content.include?("require 'rails_helper'")
    # Create a backup
    FileUtils.cp(file, "#{file}.bak")
    
    # Update to use simple_spec_helper
    updated_content = content.gsub(
      "require 'rails_helper'",
      "require_relative '#{File.dirname(file).count('/')}../simple_spec_helper'"
    )
    
    File.write(file, updated_content)
    puts "Updated: #{file}"
  end
end

# Now run all tests
system('bundle exec rspec -fd')