require File.join(File.dirname(__FILE__), "policy_details.rb")

class Client < ApplicationRecord
  self.table_name = "dbo.Client"
  self.primary_key = "D2z_Client"

  has_many :members, :class_name => "Member", :foreign_key => "MDz_Acct_No", :primary_key => "D2z_Client"
  has_many :policy_details, :class_name => "PolicyDetails", :foreign_key => "PLz_Client"
  has_many :policy_benefit_details, :class_name => "PolicyBenefitDetails", :foreign_key => "PIz_Client"

  has_many :member_supplementry_histories, -> { order("SBd_Effective DESC, SBi_Identity DESC") }, :class_name => "MemberSupplementHistory", :foreign_key => "SBz_Client"

  alias_attribute :client_number, :D2z_Client
  alias_attribute :surname, :D2z_Surname_Upp
  alias_attribute :given_names, :D2z_Given_Names_Upp
  alias_attribute :title, :D2z_Title
  alias_attribute :marital_status, :D2z_Marital_Status
  alias_attribute :birth, :D2d_Birth
  alias_attribute :birth_place, :D2z_Birth_Place
  alias_attribute :email, :D2z_Email
  alias_attribute :state, :D2z_State
  alias_attribute :sex, :D2z_Sex
  alias_attribute :occupation, :D2z_Occupation
  alias_attribute :smoker, :D2c_Smoker
  alias_attribute :country, :D2z_Country
  alias_attribute :mobile_phone, :D2z_Mobile_Phone
  alias_attribute :home_phone, :D2z_Home_Phone
  alias_attribute :work_phone, :D2z_Work_Phone
  alias_attribute :post_code, :D2z_Post_Code
  alias_attribute :suburb, :D2z_Suburb
  alias_attribute :country_code, :D2z_Country_Code
  
    alias_attribute :identity, :D2i_Identity

  def self.get(client_no)
    a_client = Client.where(:D2z_Client => padding_client_no(client_no)).first
  end

  def is_acurity_new_record?
    self.client_number.blank?
  end

  # make member_supplementry_histories ordered by identity, the first entry to determine its opt_in status
  def opt_in_flag
    member_supplementry_histories.first.opt_in_flag.strip rescue ""
  end

  def personalised_flag
    member_supplementry_histories.first.personalised_flag.strip rescue ""
  end

  def permanent_opt_in(effective_date, yes_or_no = "Y", record_type = nil)
    ms = self.member_supplementry_histories.first
    if ms.nil?
      ms = MemberSupplementHistory.new
      ms.client = self
      ms.record_type = record_type
    end
    ms.opt_in_flag = yes_or_no
    ms.effective_date = effective_date
    ms.save
  end

  def personalise(effective_date, yes_or_no = "Y", record_type = nil)
    ms = self.member_supplementry_histories.first
    if ms.nil?
      ms = MemberSupplementHistory.new
      ms.record_type = record_type
      ms.client = self.client
    end
    ms.personalised_flag = yes_or_no
    ms.effective_date = effective_date
    ms.save
  end

  # accept "D" or "D ", the with space one is used internally at Acurity
  def first_policy_benefit_of(insurance_type = "D ")
    insurance_type += " " if (insurance_type.size == 1)
    policy_benefit_details.select { |x| x.benefit_type == insurance_type }.first
  end
  
  def last_policy_benefit_of(insurance_type = "D ")
    insurance_type += " " if (insurance_type.size == 1)
    policy_benefit_details.select { |x| x.benefit_type == insurance_type }.last
  end

  def policy_benefits_of(insurance_type = "D ")
    if insurance_type.size == 1
      insurance_type += " "
    end
    policy_benefit_details.select { |x| x.benefit_type == insurance_type }
  end
  
  ## Return most current benefit of (order by effective) and is not deleted
  #  - current_benefit_of("I") # or T or D
  def current_benefit_of(insurance_type = "D")      
    insurance_type.strip!
    ip_benefits = policy_benefit_details.select{|x| x.benefit_type.strip == insurance_type && x.deleted == 'N'}
    ip_benefits = ip_benefits.select{|x| x.status == 'CU' }
    current_one = ip_benefits.sort{|a, b| a.effective <=> b.effective}.last
  end

  # override
  def acurity_create
    #puts "DEBUG: calling acurity_create"
    if !self.client_number.blank?
      puts("[DEBUG] skipping calling server already has client number")
      return
    end

    self.mobile_phone ||= "0438492160"
    self.home_phone ||= "0438492160"
    self.work_phone ||= "0438492160"
    self.email ||= "Project_testemail@qsuper.qld.gov.au"
    self.country_code ||= "AU"

    resp_xml, req_xml = AcurityWebservice::invoke_ws("addClient00001", { :client => self }, { :debug => $SHOW_WS_MSG })
    doc = Nokogiri::XML resp_xml
    doc.remove_namespaces!
    the_client_number = doc.xpath("//addClient00001Response/return").first.text
    self.client_number = the_client_number
    return the_client_number
  end

  def acurity_update
    #puts "DEBUG: calling acurity_update"
    resp_xml, req_xml = AcurityWebservice::invoke_ws("updateClientDetails00001", { :client => self }, { :debug => $SHOW_WS_MSG, :dry_run => false })
  end

  def add_policy_details(data = {})
    default_policy_data = { :status => "IF",
                            :supp_record_type => "CA",
                            :at_work_on_join => "Y",
                            :insurer => "QINSUR",
                            :commencement => Date.parse("2019-01-02"),
                            :stamp_duty => nil,
                            :fund => nil }
    new_policy = PolicyDetails.new(default_policy_data.merge(data))
    new_policy.client = self
    new_policy.save
    return new_policy
  end
  
  def name
    "#{given_names.strip} #{surname.strip}"
  end
  
end
