class MemberSupplementHistory  < ApplicationRecord
  self.table_name = 'dbo.Mbr_Supplementry_Hst'

  belongs_to :client, :foreign_key => "SBz_Client", :primary_key => "D2z_Client"
  belongs_to :member, :foreign_key => "SBz_Member", :primary_key => "MDz_Member"
  
  alias_attribute :identity, :SBi_Identity	
  alias_attribute :opt_in_flag, :SBz_User_Def_Strg02	
  alias_attribute :personalised_flag, :SBc_UserDefndFlags01
  alias_attribute :effective_date, :SBd_Effective	
  alias_attribute :record_type, :SBz_Record_Type
  alias_attribute :fund, :SBz_Fund
  alias_attribute :member_number, :SBz_Member
  
  
  def acurity_create
    #puts "DEBUG: calling acurity_update"
    resp_xml, req_xml = AcurityWebservice::invoke_ws("updateClientSupplementaryRecord00001", {:supplementary => self}, {:debug => $SHOW_WS_MSG, :dry_run => false} )
  end


  def acurity_update
    #puts "DEBUG: calling acurity_update"
    resp_xml, req_xml = AcurityWebservice::invoke_ws("updateClientSupplementaryRecord00001", {:supplementary => self}, {:debug => $SHOW_WS_MSG, :dry_run => false} )
  end

end
   