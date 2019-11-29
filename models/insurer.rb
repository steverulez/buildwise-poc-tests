require File.join(File.dirname(__FILE__), "policy_details.rb")

class Insurer < ApplicationRecord
  
  self.table_name = 'dbo.Insurer'

  alias_attribute :insurer, :IDz_Insurer
  alias_attribute :business_name, :IDz_Business_Name
# 

  def self.get(insurer_code)
    Insurer.where(:IDz_Insurer => insurer_code).first
  end
  
end
