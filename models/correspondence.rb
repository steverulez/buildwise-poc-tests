
class Correspondence < ApplicationRecord
  self.table_name = 'dbo.Correspondence_Reg'
  
  alias_attribute :corr_type, :RGz_Type
  alias_attribute :modified, :RGd_Correspondence	
  alias_attribute :status, :RGz_Status	
  alias_attribute :member_number, :RGz_Member

  belongs_to :member, :foreign_key => "RGz_Member", :primary_key => "MDz_Member"
 
end
