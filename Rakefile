# You need Ruby (Rake, RWebSpec, ci_reporter gems installed)
#   Simplest way on Windows is to install RubyShell (http://testwisely.com/downloads)

require 'rubygems'
gem 'ci_reporter'
gem 'rspec'
require 'rspec/core/rake_task'
require 'ci/reporter/rake/rspec' # use this if you're using RSpec

load File.join(File.dirname(__FILE__), "buildwise.rake")

## Settings: Customize here...
# 
BUILDWISE_URL = ENV["BUILDWISE_MASTER"] || "http://buildwise.dev"
# BUILDWISE_QUICK_PROJECT_ID = "agiletravel-quick-build-rspec"
# BUILDWISE_FULL_PROJECT_ID  = "agiletravel-full-build-rspec" # import to set for full build
 
FULL_BUILD_MAX_TIME = ENV["DISTRIBUTED_MAX_BUILD_TIME"].to_i || 60 * 60   # max build time, over this, time out
FULL_BUILD_CHECK_INTERVAL =  ENV["DISTRIBUTED_BUILD_CHECK_INTERVAL"].to_i || 20  # check interval for build complete

$test_dir =  File.expand_path( File.join( File.dirname(__FILE__), "spec" ) )  # change to aboslution path if invocation is not this directory
# rspec will create 'spec/reports' under check out dir

# List tests you want to exclude
#
def excluded_spec_files
  # NOTE, testing only for faster develping agent, remove a couple of test later
  ["selected_scripts_spec.rb", "03_passenger_spec.rb"]
end

def all_specs
  Dir.glob("#{$test_dir}/*_spec.rb")
end

def specs_for_quick_build
  # list test files to be run in a quick build, leave the caller to set full path
  [
    "00_helloworld_spec.rb",
    "01_login_spec.rb", 
    "02_flight_spec.rb",
    "03_passenger_spec.rb",
    "04_payment_spec.rb",
    "not_exists_spec.rb" # test hanlding non exists scenario
  ]
end


def determine_specs_for_quick_build
  specs_to_be_executed = []

  enable_intelligent_ordering = ENV["INTELLIGENT_ORDERING"] && ENV["INTELLIGENT_ORDERING"].to_s == "true"
  puts "[INFO] intelligent ordering? => #{enable_intelligent_ordering.to_s rescue 'false'}"
  if enable_intelligent_ordering && ENV["BUILDWISE_PROJECT_IDENTIFIER"]
    ordered_specs = buildwise_ui_test_order(ENV["BUILDWISE_PROJECT_IDENTIFIER"])
    puts "[INFO] Execution order based history of quick build: #{ordered_specs.inspect}"
    if ordered_specs.nil? || ordered_specs.compact.empty? || ordered_specs.class != Array
      specs_to_be_executed += specs_for_quick_build  if specs_to_be_executed.empty?
    else
      # neat sorting thanks to Ruby
      specs_to_be_executed = ordered_specs.dup
      specs_to_be_executed = specs_to_be_executed.sort_by{|x| ordered_specs.include?(File.basename(x)) ? ordered_specs.index(File.basename(x)) : specs_to_be_executed.count }    
      puts "[INFO] After intelligent sorting => #{specs_to_be_executed.inspect}"        
    end    
  end

  enable_dynamic_build_queue = ENV["DYNAMIC_FEEDBACK"] && ENV["DYNAMIC_FEEDBACK"].to_s == "true" && ENV["DYNAMIC_FEEDBACK_PROJECT_IDENTIFIER"]
  puts "[INFO] dynamic feedback? => #{enable_dynamic_build_queue}"  
  if enable_dynamic_build_queue
    begin
      # dynamic build process: get failed tests from last failed full build
      failed_full_build_tests = buildwise_failed_build_tests(ENV["DYNAMIC_FEEDBACK_PROJECT_IDENTIFIER"])
      if failed_full_build_tests && failed_full_build_tests.size > 0
        failed_full_build_tests.each do |x|
          full_path = File.join($spec_dir, x)
          specs_to_be_executed.insert(0, full_path) unless specs_to_be_executed.include?(full_path)
        end    
      end      
    rescue => e
      puts "[ERROR] failed to check for full build: #{e}"
    end
  end

  if specs_to_be_executed.empty?
    specs_to_be_executed = specs_for_quick_build   
  else
    specs_left_over = specs_for_quick_build - specs_to_be_executed
    specs_to_be_executed += specs_left_over
    specs_to_be_executed.flatten!
  end
  specs_to_be_executed -= excluded_spec_files
  puts "[INFO] Exclude : #{specs_to_be_executed.inspect}"

  specs_to_be_executed.uniq!
  puts "[INFO] Uniq : #{specs_to_be_executed.inspect}"

  specs_to_be_executed.reject! {|a_test|  !File.exists?(File.join($test_dir, a_test)) }
  puts "[INFO] Filter Not exists : #{specs_to_be_executed.inspect}"

  puts "[INFO] Final Test execution in order => #{specs_to_be_executed.inspect}"
  # using full path
  specs_to_be_executed = specs_to_be_executed.collect{|x| File.join($test_dir, x)}  
end

desc "run tests in this spec/ folder, option to use INTELLIGENT_ORDERING or/and DYNAMIC_FEEDBACK"
RSpec::Core::RakeTask.new("ui_tests:quick") do |t|
  
  specs_to_be_executed = determine_specs_for_quick_build();
  # t.pattern = FileList[specs_to_be_executed]
  buildwise_formatter =  File.join(File.dirname(__FILE__), "buildwise_rspec_formatter.rb")
  t.rspec_opts = "--pattern my_own_custom_order --require #{buildwise_formatter} #{specs_to_be_executed.join(' ')} --order defined"
end


desc "run quick tests from BuildWise"
task "ci:ui_tests:quick" => ["ci:setup:rspec"] do
  build_id = buildwise_start_build(:working_dir => File.expand_path(File.dirname(__FILE__)))
  puts "[Rake] new build id =>|#{build_id}|"
  begin
    # puts "[Rake] Invoke"
    FileUtils.rm_rf("spec/reports") if File.exists?("spec/reports")
    Rake::Task["ui_tests:quick"].invoke
    # puts "[Rake] Invoke Finish"
  ensure
    puts "Finished: Notify build status"
    sleep 2 # wait a couple of seconds to finish writing last test results xml file out
    puts "[Rake] finish the build"
    buildwise_finish_build(build_id)
  end
end


desc "run hello world test"
RSpec::Core::RakeTask.new("ui_tests:hello-world") do |t|
  
  specs_to_be_executed = [ "spec/00_helloworld_spec.rb" ]

  # t.pattern = FileList[specs_to_be_executed]
  buildwise_formatter =  File.join(File.dirname(__FILE__), "buildwise_rspec_formatter.rb")
  t.rspec_opts = "--pattern my_own_custom_order --require #{buildwise_formatter} #{specs_to_be_executed.join(' ')} --order defined"
end


desc "run hellow-world tests from BuildWise"
task "ci:ui_tests:hello-world" => ["ci:setup:rspec"] do
  build_id = buildwise_start_build(:working_dir => File.expand_path(File.dirname(__FILE__)))
  puts "[Rake] new build id =>|#{build_id}|"
  begin
    # puts "[Rake] Invoke"
    FileUtils.rm_rf("spec/reports") if File.exists?("spec/reports")
    Rake::Task["ui_tests:hello-world"].invoke
    # puts "[Rake] Invoke Finish"
  ensure
    puts "Finished: Notify build status"
    sleep 2 # wait a couple of seconds to finish writing last test results xml file out
    puts "[Rake] finish the build"
    buildwise_finish_build(build_id)
  end
end


desc "run acurity client test"
RSpec::Core::RakeTask.new("ui_tests:acurity-client") do |t|
  
  specs_to_be_executed = [ "spec/02_client_create_spec.rb" ]

  # t.pattern = FileList[specs_to_be_executed]
  buildwise_formatter =  File.join(File.dirname(__FILE__), "buildwise_rspec_formatter.rb")
  t.rspec_opts = "--pattern my_own_custom_order --require #{buildwise_formatter} #{specs_to_be_executed.join(' ')} --order defined"
end


desc "run acurity-client tests from BuildWise"
task "ci:ui_tests:acurity_client" => ["ci:setup:rspec"] do
  build_id = buildwise_start_build(:working_dir => File.expand_path(File.dirname(__FILE__)))
  puts "[Rake] new build id =>|#{build_id}|"
  begin
    # puts "[Rake] Invoke"
    FileUtils.rm_rf("spec/reports") if File.exists?("spec/reports")
    Rake::Task["ui_tests:acurity_client"].invoke
    # puts "[Rake] Invoke Finish"
  ensure
    puts "Finished: Notify build status"
    sleep 2 # wait a couple of seconds to finish writing last test results xml file out
    puts "[Rake] finish the build"
    buildwise_finish_build(build_id)
  end
end


## Full Build
#
#  TODO - how to determin useing RSpec or Cucumber
#
desc "Running tests in parallel"
task "ci:ui_tests:full" => ["ci:setup:rspec"] do
  build_id = buildwise_start_build(:working_dir => File.expand_path(File.dirname(__FILE__)),
                                   :ui_test_dir => ["spec"],
                                   :excluded => excluded_spec_files || [],
                                   :distributed => true
  )
  
  puts "[INFO] get BUILD ID: #{build_id} from server"
  if build_id.nil? || build_id.to_i < 1  
    raise "Build ID is not return correctly from BuildWise server, make sure the project identifier used in your Rakefile matches the BuildWise project identifer."
  end
  
  the_build_status = buildwise_build_ui_test_status(build_id)
  start_time = Time.now

  puts "[Rake] Keep checking build |#{build_id} | #{the_build_status}"
  if (FULL_BUILD_MAX_TIME < 60)
    FULL_BUILD_MAX_TIME = 60
  end
  
  if FULL_BUILD_MAX_TIME < 5 
    FULL_BUILD_MAX_TIME = 5
  end
  
  while ((Time.now - start_time ) < FULL_BUILD_MAX_TIME) # test exeuction timeout
    the_build_status = buildwise_build_ui_test_status(build_id)
    if ($last_buildwise_server_build_status != the_build_status)
      puts "[Rake] #{Time.now} Checking build status: |#{the_build_status}|"
      $last_buildwise_server_build_status = the_build_status
    end
    
    if the_build_status == "OK"
      exit 0
    elsif the_build_status == "Failed"
      exit -1
    else 
      sleep FULL_BUILD_CHECK_INTERVAL  # check the build status every minute
    end
  end
  puts "[Rake] Execution UI tests expired"
  exit -2
end


desc "run all tests in this folder"
RSpec::Core::RakeTask.new("go") do |t|
  test_files = Dir.glob("*_spec.rb") + Dir.glob("*_test.rb") - excluded_test_files
  t.pattern = FileList[test_files]
  t.rspec_opts = "" # to enable warning: "-w"
end


desc "testing - bomb"
task "bomb" do
  puts "Testing bad task"
  raise "Boom..."
end

desc "Generate stats for UI tests"
task "test:stats" do

  ui_test_dir = File.dirname(__FILE__)
  STATS_SOURCES = {
      "Tests" => "#{ui_test_dir}/spec",
      "Pages" => "#{ui_test_dir}/pages",
      "Helpers" => "#{ui_test_dir}/*_helper.rb",
  }

  test_stats = {"lines" => 0, "test_suites" => 0, "test_cases" => 0, "test_lines" => 0}
  page_stats = {"lines" => 0, "classes" => 0, "methods" => 0, "code_lines" => 0}
  helper_stats ={"lines" => 0, "helpers" => 0, "methods" => 0, "code_lines" => 0}

  # Tests
  directory = STATS_SOURCES["Tests"]
  Dir.foreach(directory) do |file_name|
    next if file_name == "." || file_name == ".." || file_name == "selected_scripts_spec.rb"
    next if File.directory?(File.join(directory, file_name))
    f = File.open(directory + "/" + file_name)
    test_stats["test_suites"] += 1
    while line = f.gets
      test_stats["lines"] += 1
      test_stats["test_cases"] += 1 if line =~ /^\s*it\s+['"]/ || line =~ /^\s*story\s+['"]/ || line =~ /^\s*test_case\s+['"]/
      test_stats["test_lines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
    end
    f.close
  end
  # puts test_stats.inspect

  # Pages
  directory = STATS_SOURCES["Pages"]
  Dir.foreach(directory) do |file_name|
    next if file_name == "." || file_name == ".."
    f = File.open(directory + "/" + file_name)
    while line = f.gets
      page_stats["lines"] += 1
      page_stats["classes"] += 1 if line =~ /class [A-Z]/
      page_stats["methods"] += 1 if line =~ /def [a-z]/
      page_stats["code_lines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
    end
    f.close
  end

  # Helpers
  # directory = File.dirname( STATS_SOURCES["Helpers"])
  # helper_wildcard = File.basename( STATS_SOURCES["Helpers"])
  # puts directory
  # puts helper_wildcard
  Dir.glob(STATS_SOURCES["Helpers"]).each do |helper_file|
    f = File.open(helper_file)
    helper_stats["helpers"] += 1
    while line = f.gets
      helper_stats["lines"] += 1
      helper_stats["methods"] += 1 if line =~ /def [a-z]/
      helper_stats["code_lines"] += 1 unless line =~ /^\s*$/ || line =~ /^\s*#/
    end
    f.close
  end

  total_lines = helper_stats["lines"] + page_stats["lines"] + test_stats["lines"]
  total_code_lines = helper_stats["code_lines"] + page_stats["code_lines"] + test_stats["test_lines"]

  puts "+------------+---------+---------+---------+--------+"
  puts "| TEST       |   LINES |  SUITES |   CASES |    LOC |"
  puts "|            | #{test_stats['lines'].to_s.rjust(7)} " + "| #{test_stats['test_suites'].to_s.rjust(7)} " + "| #{test_stats['test_cases'].to_s.rjust(7)} " + "| #{test_stats['test_lines'].to_s.rjust(6)} " + "|"
  puts "+------------+---------+---------+---------+--------+"
  puts "| PAGE       |   LINES | CLASSES | METHODS |    LOC |"
  puts "|            | #{page_stats['lines'].to_s.rjust(7)} " + "| #{page_stats['classes'].to_s.rjust(7)} " + "| #{page_stats['methods'].to_s.rjust(7)} " + "| #{page_stats['code_lines'].to_s.rjust(6)} " + "|"
  puts "+------------+---------+---------+---------+--------+"
  puts "| HELPER     |   LINES |   COUNT | METHODS |    LOC |"
  puts "|            | #{helper_stats['lines'].to_s.rjust(7)} " + "| #{helper_stats['helpers'].to_s.rjust(7)} " + "| #{helper_stats['methods'].to_s.rjust(7)} " + "| #{helper_stats['code_lines'].to_s.rjust(6)} " + "|"
  puts "+------------+---------+---------+---------+--------+"
  puts "| TOTAL      | " + total_lines.to_s.rjust(7) + " |         |         |" + total_code_lines.to_s.rjust(7) + " |"
  puts "+------------+---------+---------+---------+--------+"

end