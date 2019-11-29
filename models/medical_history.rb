class MedicalHistory < ApplicationRecord
  self.table_name = 'dbo.Mbr_Medical_History'
  
  alias_attribute :insurance_category, :MHz_Insurance_Cat
  
  belongs_to :fund, :foreign_key => "MHz_Fund", :primary_key => "FRz_Fund"
  belongs_to :member, :foreign_key => "MHz_Member_No", :primary_key => "MDz_Member"
  
end