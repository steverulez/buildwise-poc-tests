require "rubygems"
require "rspec"

require "net/http"
require "net/https"
require "faker"       # general test data, such as person name or email
require "active_support/all"  # A common ruby language extension, such as 3.days.ago
require "nokogiri"    # for pasing XML
require "csv"
require "pstore"
require "cgi"
require "json"        # for parsing JSON string

gem "pdf-reader"      # for parsing PDF, after verify can open PDF, may use 'bin/pdftotext.exe' to verify content
require "pdf/reader"

# use utils in RWebSpec and better integration with TestWise
require "#{File.dirname(__FILE__)}/rwebspec_utils.rb"

# when running in TestWise, it will auto load TestWiseRuntimeSupport, ignore otherwise
if defined?(TestWiseRuntimeSupport)
  ::TestWise::Runtime.load_webdriver_support # for selenium webdriver support
end

# The default base URL for running from command line or continuous build process
$BASE_URL = "http://"

# This is the helper for your tests, every test file will include all the operation
# defined here.
module TestHelper
  include RWebSpecUtils
  
  include TestWiseRuntimeSupport if defined?(TestWiseRuntimeSupport) 

  def site_env(default = "DEV18")
    the_env = $TESTWISE_PROJECT_BASE_URL || ENV["BASE_URL"] || ENV["SERVER"] || default
    return the_env
  end

  def mol_url(server)    
    if server =~ /dit12/i
      return "https://dev05-portal.gso.internal"
    elsif  server =~ /dev/i
      raise " Member Online not supported on DEV environments except DIT12"
    else
      return "https://#{server.downcase}-portal.gso.internal"
    end
  end
  
  def escape_html(str)
    CGI.escapeHTML(str)
  end
  
  # Get full path a test data file
  #   e.g. test_file("rates.csv") will refer to C:\work\insurance-automated-tests\testdata\rates.csv
  def test_file(file_name)
    File.join(File.dirname(__FILE__), "testdata", file_name)
  end
  
  def template_file(file_name)
    File.join(File.dirname(__FILE__), "templates", file_name)  
  end
  
  
  def bin_file(file_name)
    File.join(File.dirname(__FILE__), "bin", file_name)
  end

  def screenshots_dir()
    if ENV["SCREENSHOTS_DIR"] && Dir.exists?(ENV["SCREENSHOTS_DIR"])
      return ENV["SCREENSHOTS_DIR"]
    else
      File.join(File.dirname(__FILE__), "tmp", "screenshots")
    end
  end

  def pdfs_dir()
    if ENV["LETTER_PDFS_DIR"] && Dir.exists?(ENV["LETTER_PDFS_DIR"])
      return ENV["LETTER_PDFS_DIR"]
    else
      File.expand_path File.join(File.dirname(__FILE__), "tmp", "pdfs")
    end
  end

  def sql_file(filename)
    File.expand_path File.join(File.dirname(__FILE__), "sqls", filename)
  end

  # get full path a temporary file 
  #   e.g. tmp_file("result.txt") will refer to C:\work\insurance-automated-tests\tmp\result.txt
  def tmp_file(filename)
    File.expand_path File.join(File.dirname(__FILE__), "tmp", filename)
  end

  # Write content to a temporary files to 'tmp' folder under the test project
  #  - this is good for debugging long content
  def dump_tmp_file(filename, content)
    fio = File.open(tmp_file(filename), "w")
    fio.puts(content)
    fio.flush
    fio.close
  end

  def print_formatted_xml(str)
    puts pretty_print_xml(str)
    # puts "<code class='xml'>" + escape_html(pretty_print_xml(str)) + "</code>"
  end

  # take a client number and format it in a way easier to use in Acurity queries
  #   - padded spaces before and after to make 17 in length
  def padding_client_no(a_no)
    the_padded = a_no.rjust(13, " ").ljust(17, " ")
  end

  def verify_valid_pdf(pdf_file, opts = {})
    reader = PDF::Reader.new(pdf_file)
    puts reader.pdf_version
    puts reader.info
    if opts[:creator]
      raise "The creator in pdf does not include '#{opts[:creator]}'" unless reader.info[:Creator].include?(opts[:creator])
    end
    if opts[:page_count] && opts[:page_count].to_i > 0
      raise "The page count is not '#{opts[:page_count]}'" unless reader.page_count == opts[:page_count].to_i
    end
  end

  def verify_pdf_content(pdf_file, texts_to_check = [])
    if File.exists?(bin_file("pdftotext.exe"))
      pdf_text_file = File.join(pdfs_dir, File.basename(pdf_file).gsub(".pdf", ".txt"))
      cmd = bin_file("pdftotext.exe") + " " + pdf_file + " " + pdf_text_file
      system(cmd)
      sleep 0.5
      pdf_text_content = File.read(pdf_text_file)

      texts_to_check.each do |text|
        raise "The text '#{text}' not found in PDF, converted text file: #{pdf_text_file}" unless pdf_text_content.include?(text)
      end
      return pdf_text_content
    else
      puts("Unable to locate pdftotext.exe, checking PDF content is skipped.")
    end
  end

  def output_dir
    the_output_dir = ENV["RECONCILIATION_OUTPUT_DIR"]
    if the_output_dir.blank?
      the_output_dir = File.join(File.dirname(__FILE__), "output")
    end
    return File.expand_path(the_output_dir)
  end

  # Write to a csv file (under ouptut dir see above)
  #
  def write_to_csv_array(array_array, file_name, field_headings = [])
    csv_file = File.join(output_dir(), file_name)
    CSV.open(csv_file, "wb") do |csv|
      csv << field_headings
      array_array.each do |entry|
        if entry.class == String
          entry = [entry]
        end
        csv << entry
      end
    end
  end

  def timing(message, &block)
    start_time = Time.now
    message = message.rjust(10, " ")
    yield
    puts "[BENCHMARK] [#{message}] #{(Time.now - start_time).round(2)}"
  end

  def debugging?
    run_in_testwise? && ENV["TESTWISE_RUNNING_AS"] == "test_case"
  end

  def run_in_testwise?
    ENV["RUN_IN_TESTWISE"].to_s == "true"
  end
  
  # just verify test scripts, don't actually run test steps inside
  def is_dry_run?
    ENV["DRY_RUN"] && ENV["DRY_RUN"].to_s == "true"
  end
  
  # compare a transaction effective date to determine ZA, ZB, ZC and ZD corresponse type
  def determine_za_zb_zc_zd(eff_date, run_date = Date.today)
    #ZA RANGE
    max_6_month_date = run_date.advance(months: -6)
    min_6_month_date = max_6_month_date.advance(days: -14)
    puts("6 Months: #{min_6_month_date.to_s} => #{max_6_month_date.to_s}")

    #ZB RANGE
    max_9_month_date = run_date.advance(months: -9)
    min_9_month_date = max_9_month_date.advance(days: -14)
    puts("9 Months: #{min_9_month_date.to_s} => #{max_9_month_date.to_s}")

    #ZC RANGE
    max_12_month_date = run_date.advance(months: -12)
    min_12_month_date = max_12_month_date.advance(days: -14)
    puts("12 Months: #{min_12_month_date.to_s} => #{max_12_month_date.to_s}")

    #ZD RANGE
    max_13_month_date = run_date.advance(months: -13)
    puts("13 Months:  #{max_13_month_date.to_s}")

    letter_type = nil
    if eff_date > min_6_month_date && eff_date < max_6_month_date
      letter_type = "ZA"
    elsif eff_date > min_9_month_date && eff_date < max_9_month_date
      letter_type = "ZB"
    elsif eff_date > min_12_month_date && eff_date < max_12_month_date
      letter_type = "ZC"
    elsif eff_date < max_13_month_date
      letter_type = "ZD"
    else
      letter_type = "Active"
    end
    return letter_type
  end
end
