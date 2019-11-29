require 'active_record'
require 'erb'
require 'tilt'

gem 'tiny_tds'
gem 'activerecord-sqlserver-adapter'
gem 'tiny_tds'
require 'tiny_tds'

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each { |file| load file }

env_name =  $TESTWISE_PROJECT_BASE_URL 
env_name ||= ENV["SERVER"]
env_name = ENV["BASE_URL"]
env_name ||= "DEV18"

=begin
db_yml_template= Tilt::ERBTemplate.new( File.expand_path("../config/database.yml", __FILE__) )
data = {}
data["acurity_user_name"]= (ENV["ACURITY_USER_NAME"] && !ENV["ACURITY_USER_NAME"].blank?) ? ENV["ACURITY_USER_NAME"] : "zhzhan"
data["acurity_user_pass"]= (ENV["ACURITY_USER_PASS"] && !ENV["ACURITY_USER_PASS"].blank?) ? ENV["ACURITY_USER_PASS"] : "BadPass"

db_config = YAML::load(db_yml_template.render(nil, data))
puts "[INFO] Connecting to ENV: #{env_name}"
ActiveRecord::Base.establish_connection(db_config[env_name])
=end

module DatabaseTestHelper
  
  def connect_database(env_name = nil)
    env_name ||= site_env()
    db_config = database_config()
    ActiveRecord::Base.establish_connection(db_config[env_name])
    puts "Connecting to DB Server: #{env_name}"

    load File.expand_path(File.join( File.dirname(__FILE__), "models", "client.rb"))
    load File.expand_path(File.join( File.dirname(__FILE__), "models", "policy_benefit_details.rb"))
    load File.expand_path(File.join( File.dirname(__FILE__), "models", "rate.rb"))
    return env_name
  end

  def database_config()    
    if $db_config
      return $db_config
    end
        
    user = ENV["ACURITY_USER_NAME"]
    pass = ENV["ACURITY_USER_PASS"] 
    
    if user.blank? && pass.blank? && File.exists?(File.join(File.dirname(__FILE__), "env-var.yml"))
      require 'yaml'
      env_hash = YAML.load(File.read File.join(File.dirname(__FILE__), "env-var.yml"))
      user = env_hash["ACURITY_USER_NAME"]
      pass = env_hash["ACURITY_USER_PASS"]
      puts "Load Env from local env-var.yml, ACURITY_USER_NAME=" + user
    end    
    
    db_yml_template= Tilt::ERBTemplate.new( File.expand_path("../config/database.yml", __FILE__) )
    data = {"acurity_user_name" => user, "acurity_user_pass" => pass}
    $db_config = YAML::load(db_yml_template.render(nil, data))
    return $db_config
  end
  
  def db_hash(db_config)    
    the_hash = {:username => db_config["username"], :password =>  db_config["password"], 
   :dataserver => db_config["dataserver"], :database => db_config["database"] }     
    #puts the_hash.inspect
    return the_hash
  end

  def load_table(table_name, class_name = nil)
    begin
      ActiveRecord::Base.connection
    rescue =>e
      raise "No database connection setup yet, use connect_to_database() method"
    end
    class_name ||= table_name.classify
    # define the class, so can use ActiveRecord in
    # such as
    #   Perosn.count.should == 2
    def_class = "class ::#{class_name} < ActiveRecord::Base; self.table_name = '#{table_name}';  end"
    eval def_class
    return def_class
  end

  def timing(msg = nil, &block)
    start_time = Time.now
    yield
    puts("[Timing] {#{msg}} #{Time.now - start_time}")
  end

  def padded_client_no(cli_no)
    cli_no.rjust(13, " ").ljust(17, " ")
  end

  # return client_number, member
  # if second hash is nil, no member
  def create_default_client(client_opts = {}, member_opts = {})
    last_name   = Faker::Name.last_name.upcase
    given_names = Faker::Name.first_name.upcase
    birth_date  = Faker::Date.between(from: 60.years.ago, to: 21.years.ago)
    title       = Faker::Name.prefix.gsub(".", "").upcase
    sex         = ["M", "F",].sample
    marital_status = ["D", "M", "S", "W", "X", nil].sample
    # email = Faker::Internet.email
    email = "Project_testemail@qsuper.qld.gov.au"
    birth_place = "TEST AUTOMATION FARM"
    post_code = "4000"
    
    default_options = {
      :surname => last_name,
      :given_names => given_names,
      :birth => birth_date,
      :title => title,    # Mrs. => MRS
      :sex => sex,
      :marital_status => marital_status,
      :state => "QLD",
      :birth_place => birth_place,
      :email=> email,
      :post_code => post_code
    }
    puts "[INFO] merge client options: #{client_opts}"
    client = Client.new(default_options.merge(client_opts))
    client.save # will create one in Acurity

    default_member_options = {
      :fund => "GSUP", 
      :payroll => "031000", 
      :category => "AP",
      :client_number => client.client_number, 
      :joined_fund => Faker::Date.between(from: 3.years.ago, to: 1.years.ago).to_s,
      :status => "C"
    }
    unless member_opts.nil?  
      member = Member.new(default_member_options.merge(member_opts))
      member.save
    end
    
    if member 
      return client.client_number, member.member, client
    else
      return client.client_number, nil, client
    end
  end
  
  alias_method  :create_client, :create_default_client

  # Create a client then calling U9IU to create default policy
  def create_client_with_policy(client_opts = {}, member_opts = {})
    client_number, member_number, client_obj = create_default_client(client_opts, member_opts)
    puts("[INFO] New client \"#{client_obj.given_names} #{client_obj.surname}\": #{client_number}, Member: #{member_number}")
    
    joined_fund_date = member_opts[:joined_fund]
    if joined_fund_date.blank?
      effective_date = Date.today.last_year.strftime("%d/%m/%Y")
    else
      effective_date = Date.parse(joined_fund_date).strftime("%d/%m/%Y")
    end
    
    resp_data = do_job("U9IU", :client_number => client_number, :member_number => member_number,
              :effective_date => effective_date, :fund => "GSUP")
    puts resp_data[:reportOutput]
    expect(resp_data[:reportOutput]).to include("Completed without errors")
    return client_number, member_number
  end
  

  def create_policy_benfit(client, policy_details, pbd_data)
    pbd = PolicyBenefitDetails.new(pbd_data)
    pbd.client = client      
    pbd.policy_details = policy_details      
    if policy_details && policy_details.supp_record_type
      pbd.supp_record_type = policy_details.supp_record_type
    end        
    pbd.save    
  end
  
  def do_job(message_type, hash = {})
    hash[:message_type] = message_type
    resp_xml, req_xml = AcurityWebservice::invoke_ws("doJob00001", hash )
    
    doc = Nokogiri::XML(resp_xml, &:noblanks)
    doc.remove_namespaces!
    
    return_elem = doc.xpath("//doJob00001Response/return").first 
    error_message = return_elem["errorMessage"]
    report_output = return_elem["reportOutput"]    
    return {:requestXml => req_xml, :responseXml => resp_xml, :errorMessage => error_message, :reportOutput => report_output}    
  end
  
  def pretty_print_xml(xml_str)
    doc = Nokogiri::XML(xml_str, &:noblanks)
    return doc.to_s
  end
  
  # return a list of non-opt-in clients
  def get_sample_non_opt_in_client_numbers
    the_max_pbd_id = PolicyBenefitDetails.last.identity
    puts the_max_pbd_id 
    min_pbd_identity = the_max_pbd_id - Faker::Number.between(from: 200000, to: 202000)
    max_pbd_identity = the_max_pbd_id - Faker::Number.between(from: 170000, to: 190000)
    
non_opt_in_client_query = <<EOM
SELECT DISTINCT TOP 100 PI.PIz_Client, PI.Num FROM (
              SELECT PIz_Client, MAX(PId_Effective) Num
              FROM Policy_Benefit_Dtls					  
			  WHERE  PIz_Status='CU' AND PIz_Insurance_Cat='CA'
        AND PIz_Benefit_Type='I' AND PIz_Benefit_Feature = 'U'
			  AND PIi_Identity > #{min_pbd_identity} AND  PIi_Identity < #{max_pbd_identity} 
			  GROUP BY PIz_Client
              ) AS PI
WHERE NOT EXISTS (
 SELECT SBz_Client FROM Mbr_Supplementry_Hst AS MSH
 WHERE PI.PIz_Client = MSH.SBz_Client 
 AND MSH.SBz_User_Def_Strg02='Y'  
)
EOM
    puts("Query to find a client:\n" + non_opt_in_client_query)
    
    results = PolicyBenefitDetails.find_by_sql(non_opt_in_client_query)
    client_numbers = results.pluck("PIz_Client")
  end
  
  # return a newly created client 
  def get_new_client_opt_in(effective_date = nil)
    client = get_new_client_not_opt_in
    effective_date = effective_date || Date.yesterday.strftime("%d/%m/%Y")

    ms = client.member_supplementry_histories.first
    ms.opt_in_flag = 'Y'
    ms.effective_date = effective_date
    ms.acurity_update      
    sleep 1
    puts("#{client_number} opt in on #{effective_date}")
    return client
  end
  
  # return a newly created client 
  def get_new_client_not_opt_in(client_data = {}, member_data_opts = {})
    default_member_opts = { :joined_fund => Faker::Date.between(from: 3.years.ago, to: 1.years.ago).to_s }
    member_data = member_data_opts.merge(default_member_opts)
    client_number, member_number = create_client_with_policy(client_data, member_data)    
    client = Client.get(client_number)
    return client
  end
  
  
 
  # def: define a resuable function
  #  example use: generate_client_birth_and_join_date(15)
  #  return birth date that given years ago, joined date 1..3 month ago
  #         the birth date's month is at least 1 month ahead of join month
  #
  # make sure birth date is after July and different from today's month  
  def generate_client_birth_and_join_date(years)
    joined_fund_date = Faker::Date.between(from: 20.days.ago, to: 1.month.ago)
    rand_day_diff = rand(30) # generate a random number 0..29
    # guaranteed one month after and random date upto another month
    client_birth_date = joined_fund_date.years_ago(years)   
    current_month = Date.today.month 
    if client_birth_date.month < 7
      # we make it sep      
      puts("generate client_birth_date: #{client_birth_date}, month is #{client_birth_date.month}")
      month_diff = 11 - client_birth_date.month
      client_birth_date = client_birth_date.advance(months: month_diff)
      puts("Changed date forced in after July: #{client_birth_date}, month is #{client_birth_date.month}")
    end
    
    if (client_birth_date.month == current_month)
      # we make it different to before or after
      puts("Make it different from current month")
      if current_month == 12
        client_birth_date.advance(months: -1)
      else 
        client_birth_date.advance(months: 1)
      end
    end
    
    puts("Generated client_birth_date: #{client_birth_date}")

    return client_birth_date, joined_fund_date
  end
   
end
