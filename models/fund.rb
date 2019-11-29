class Fund < ApplicationRecord
  self.table_name = 'dbo.Fund'
  self.primary_key = "FRz_Fund"
  
  alias_attribute :fund, :FRz_Fund
  alias_attribute :name, :FRz_Fund_Name

end
