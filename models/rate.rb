class Rate < ApplicationRecord
  self.table_name = 'dbo.Table1'
  
  alias_attribute :code, :TRz_Code	
end
