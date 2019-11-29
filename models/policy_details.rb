class PolicyDetails < ApplicationRecord
  self.table_name = "dbo.Policy_Details"
  belongs_to :client, :class_name => "Client", :foreign_key => "PLz_Client"

  has_many :benefit_details, :class_name => "PolicyBenefitDetails", :primary_key => "policy_number", :foreign_key => "policy_number"

  alias_attribute :policy_number, :PLl_Policy_Number
  alias_attribute :insurer, :PLz_Insurer
  alias_attribute :status, :PLz_Status
  alias_attribute :supp_record_type, :PLz_Supp_Record_Type
  alias_attribute :commencement, :PLd_Commencement
  alias_attribute :at_work_on_join, :PLc_At_Work_On_Join
  alias_attribute :stamp_duty, :PLc_Stamp_Duty
  alias_attribute :fund, :PLz_Fund
  alias_attribute :member_number, :PLz_Member
  alias_attribute :identity, :PLi_Identity
  
    
  def left_padded_client_number
    client.client_number.strip.rjust(13, " ")
  end
  
  # override
  def acurity_create
    #puts "DEBUG: calling acurity_create"
    if !self.identity.blank?
      puts("[DEBUG] skipping calling server already has identity")
      return
    end

    resp_xml, req_xml = AcurityWebservice::invoke_ws("createInsurancePolicy", { :policy => self }, { :debug => $SHOW_WS_MSG })
    doc = Nokogiri::XML resp_xml
    doc.remove_namespaces!

    the_policy_number = doc.xpath("//createInsurancePolicyResponse/return/PLl_Policy_Number").text
    self.policy_number = the_policy_number
    return the_policy_number
  end

  def acurity_update
    #puts "DEBUG: calling acurity_update"
    resp_xml, req_xml = AcurityWebservice::invoke_ws("updateInsurancePolicyAndPolicyBenefits", { :policy => self }, { :debug => $SHOW_WS_MSG, :dry_run => false })
  end

  def add_policy_benefit_details(data = {})
    default_benefit_data = { :effective => Date.parse("2019-07-01"),
                             :benefit_type => "I",
                             :insurance_category => "BA",
                             :benefit_feature => "F",
                             :status => "CU",
                             :waiting_period => "3",
                             :benefit_period => "2",
                             :occupation => "3" }

    policy_benefit_details = PolicyBenefitDetails.new(default_benefit_data.merge(data))
    policy_benefit_details.policy_details = self
    if self.supp_record_type
      policy_benefit_details.supp_record_type = self.supp_record_type
    end
    policy_benefit_details.client = self.client
    policy_benefit_details.save
    return policy_benefit_details
  end
end
