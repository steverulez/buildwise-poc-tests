class PolicyBenefitDetails < ApplicationRecord
  self.table_name = 'dbo.Policy_Benefit_Dtls'
  belongs_to :client, :class_name => "Client", :foreign_key => "PIz_Client", :primary_key => "D2z_Client"
  belongs_to :policy_details, :class_name => "PolicyDetails", :foreign_key => "PIl_Policy_Number", :primary_key => "PLl_Policy_Number"
  
  alias_attribute :status, :PIz_Status
  alias_attribute :policy_number, :PIl_Policy_Number
  alias_attribute :client_number, :PIz_Client
  alias_attribute :benefit_type, :PIz_Benefit_Type
  alias_attribute :benefit_feature, :PIz_Benefit_Feature
  alias_attribute :insurance_category, :PIz_Insurance_Cat
  alias_attribute :supp_record_type, :PIz_Supp_Record_Type
  alias_attribute :waiting_period, :PIz_Waiting_Period
  alias_attribute :benefit_period, :PIz_Benefit_Period	
  alias_attribute :premium, :PIf_Premium	
  alias_attribute :significant_event, :PIz_SignificantEvent	
  alias_attribute :financial_uwrite, :PIz_Financial_Uwrite
  alias_attribute :occupation, :PIz_Occupation
  alias_attribute :units_default, :PIf_Units_Default
  alias_attribute :units_additional, :PIf_UnitsAdditional  
  alias_attribute :sum_insured, :PIf_SI_Default  

  
  # effective cannot be updated directly with save()
  alias_attribute :effective, :PId_Effective 
  
  alias_attribute :dollar_default, :PIf_Dollar_Default
  alias_attribute :dollar_additional, :PIf_DollarAdditional
  alias_attribute :fees, :PIf_Fees
  alias_attribute :salary, :PIf_Salary
  alias_attribute :exclusions_apply, :PIc_Exclusions_Apply
  alias_attribute :pec_start, :PId_PEC_Start 
  alias_attribute :pec_end, :PId_PEC_End
  alias_attribute :crb, :PIf_CRB
  alias_attribute :benefit_roll_in, :PIc_Benefit_Roll_In
  
  alias_attribute :supp_record_type, :PIz_Supp_Record_Type
  alias_attribute :deleted, :PIc_Deleted	
  alias_attribute :identity, :PIi_Identity	


  def to_s
    {:status => self.PIz_Status, :policy_number => self.PIl_Policy_Number }
  end

  
  def self.most_recent_for(client_id)
    where(:PIz_Client => client_id).group("PIz_Client").map{|_client, pbds| pbds.max(&:PId_Effective)}
  end
  
  def insurer
    self.policy_details.insurer
  end
  
   # override
  def acurity_create
    if !self.identity.blank?
      puts("[DEBUG] skipping calling server already has identity")
      return
    end

    resp_xml, req_xml = AcurityWebservice::invoke_ws("createPolicyBenefit", {:benefit => self}, {:debug => $SHOW_WS_MSG} )
    doc = Nokogiri::XML resp_xml
    doc.remove_namespaces!
    
    the_beneifit_number = doc.xpath("//createPolicyBenefitResponse/return").first.text
    return the_beneifit_number
  end

  def acurity_update
    puts "DEBUG: PolicyBenefitDetails.calling acurity_update"
    resp_xml, req_xml  = AcurityWebservice::invoke_ws("updateInsurancePolicyAndPolicyBenefits", {:benefit => self}, {:debug => $SHOW_WS_MSG} )
  end

   
end