class GeneralLedger < ApplicationRecord
  self.table_name = 'dbo.General_Ledger'
  
  alias_attribute :identity, :GLi_Identity	
end
