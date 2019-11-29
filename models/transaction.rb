class Transaction < ApplicationRecord
 
  self.table_name = 'dbo.General_Ledger'
 
  alias_attribute :tran_Fund, :GLz_Fund
  alias_attribute :tran_div, :GLz_Division
  alias_attribute :tran_tran_ref, :GLl_Trans_Ref
  alias_attribute :tran_type, :GLz_Tran_Type	
  alias_attribute :tran_acc, :GLz_Account
  alias_attribute :tran_preservation, :GLz_Preservation	
  alias_attribute :tran_cont_type,  :GLz_Cont_Acct
  alias_attribute :tran_effective, :GLd_Effective	
  alias_attribute :tran_deb_cr, :GLz_Debit_Or_Credit
  alias_attribute :tran_amount, :GLf_Amount
  alias_attribute :member_number, :GLz_Member

  belongs_to :member, :foreign_key => "GLz_Member", :primary_key => "MDz_Member"
  
end