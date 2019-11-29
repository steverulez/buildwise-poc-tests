require 'erb'
require 'tilt'
require 'cgi'
require 'nokogiri'

# A wrapper of functions that invoke Acurity WebServices
#
# 
class AcurityWebservice
  
  def self.end_user
    #"xs-autotest1"
    "xs-autotest2" # works
  end
  
  def self.verbose_mode?
    (ENV["VERBOSE"] &&  ENV["VERBOSE"].to_s == "true") || $SHOW_WS_MSG
  end

  def self.get_env_host
    if ENV['BASE_URL'] 
      "acurity-iws-#{ENV['BASE_URL'].downcase}"
    elsif ENV['SERVER'] 
      "acurity-iws-#{ENV['SERVER'].downcase}"
    else
      # default to dev18
      "acurity-iws-dev18"
    end
  end
  
  def self.escape_html(str)
    CGI.escapeHTML(str)
  end
  
  def self.pretty_print_xml(xml_str)
    Nokogiri::XML(xml_str, &:noblanks).to_s    
  end
  
  ##
  #  A helper method that print out XML
  # 
  def self.dump_xml(xml_str)
    if ENV["RUN_IN_BUILDWISE_AGENT"] && ENV["RUN_IN_BUILDWISE_AGENT"].to_s == "true" 
      # when running in Build agent, keep raw format (and faster too)
      puts(xml_str)
    elsif ENV["BUILDWISE_MASTER"] && ENV["BUILDWISE_MASTER"].strip.size > 3
      puts("<h6>WS Request/Response:</h6><code class='xml'>#{escape_html(pretty_print_xml(xml_str))}</code>")
    else
      puts(pretty_print_xml(xml_str))
    end    
  end
  
  ## 
  #  The main function to invoke Acurity WS, example usage:
  # 
  #   AcurityWebservice::invoke_ws("updateClientDetails00001", { :client => self }, { :debug => $SHOW_WS_MSG, :dry_run => false })
  #   resp_xml, req_xml = AcurityWebservice::invoke_ws("doJob00001", { :message_type => "U9IU", 
  #     :client_number => client_number, :member_number => member_number,
  #     :effective_date => effective_date, :fund => "GSUP" } )
  # 
  #  the first parameter is webservice name such as 'addClient00001',
  #     
  def self.invoke_ws(ws_name, data = {}, opts= {})
    data[:end_user] ||= self.end_user
  
    template_file = File.expand_path( File.join( File.dirname(__FILE__), "..", "templates", "#{ws_name}-request.xml.erb" ) )
    template = Tilt::ERBTemplate.new(template_file)      
    request_xml = template.render(nil, data)
    
    dump_xml(request_xml) if self.verbose_mode?
    
    the_env_host = self.get_env_host()
    unless opts[:dry_run]  # if pass :dry_run, skip actual execution
    start_time = Time.now
    
    # Example:
    #   host => acurity-iws-dev18
    #   port => 7580
    #   endpoint_path => /AcurityWebServices/Client
    #
    # Code below post reqeust XML to e.g. http://acurity-iws-dev18:7580/AcurityWebServices/Client
    http = Net::HTTP.new(the_env_host, 7580)    
      resp, data = http.post(ws_endpoint_lookups[ws_name], request_xml, 
        # http headers
        {
          "SOAPAction" => "",
          "Content-Type" => "text/xml",
          "Host" => "acurity-iws-dev18:7580"
        }
      )
             
      # dump_xml(resp.body) if self.verbose_mode?      
      
      unless resp.code == "200"    # if error, response code not equal 200
        puts "ERROR: #{resp.body}"
        raise "calling webserice error: #{resp.code} "        
      end
      
      puts "[BENCHMARK] [#{the_env_host}] {#{ws_name}} #{Time.now - start_time}"
      
      # save it first, maybe of use later
      store_key = "ws-#{Time.now.strftime('%Y%m%d%H%M%S')}.pstore"
      store_file = File.expand_path( File.join( File.dirname(__FILE__), "..", "tmp", store_key ) )
      store = PStore.new(store_file)
      store.transaction do
        store[:request_xml] = request_xml
        store[:response_xml] = resp.body
      end
      
      return resp.body, request_xml      
    else
      return "NO DATA", "NO DATA"
    end
  end
  
  ## 
  #  Every WebService must assoicated with an end point.
  #  To get the endpoint, Create a test project with WSDL, you will see the end point.
  #  We only need the the path part (excluding host and port)
  # 
  def self.ws_endpoint_lookups
    {
      "getClientDetails00001" => "/AcurityWebServices/Client",
      "getClientDetails00002" => "/AcurityWebServices/Client",
      "getMemberAccounts00001" => "/AcurityWebServices/Client",
      "addClient00001" => "/AcurityWebServices/Client",
      "updateClientDetails00001" => "/AcurityWebServices/Client",
      
      "addMember00001" => "/AcurityWebServices/Member",
      "getMemberAndClientDetails00001" => "/AcurityWebServices/Member",
      "updateMemberDetails00001" => "/AcurityWebServices/Member",
      
      "getInsurer" => "/AcurityWebServices/Insurance",
      "getInsurancePolicyAndPolicyBenefits" => "/AcurityWebServices/Insurance",      
      "updateInsurancePolicyAndPolicyBenefits" => "/AcurityWebServices/Insurance",      
      
      "updateClientSupplementaryRecord00001" => "/AcurityWebServices/MemberSupplementary",

      "createInsurancePolicy" => "/AcurityWebServices/Insurance",
      "createPolicyBenefit" => "/AcurityWebServices/Insurance",
      
      "doJob00001" => "/AcurityWebServices/DoJob",
      
      "getMemberTransactions00001" => "/AcurityWebServices/Accounting",
      "getMemberAccountsWithBalancesByClientId00001" => "/AcurityWebServices/Accounting",
      "getInvestmentBreakdown00001" => "/AcurityWebServices/Accounting"
    }
  end
  
  
end
