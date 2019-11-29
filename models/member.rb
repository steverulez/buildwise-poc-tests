class Member < ApplicationRecord
  self.table_name = 'dbo.Member'
  self.primary_key = "MDz_Member"

  belongs_to :client, :foreign_key => "MDz_Acct_No", :primary_key => "D2z_Client"

  has_many :member_supplementry_histories, -> {order("SBd_Effective DESC, SBi_Identity DESC" )}, :class_name => "MemberSupplementHistory", :foreign_key => "SBz_Member"

  has_many :correspondences, :foreign_key => "RGz_Member", :primary_key => "MDz_Member"

  alias_attribute :client_number, :MDz_Acct_No
  alias_attribute :given_names, :MDz_Given_Names
  alias_attribute :surname, :MDz_Surname
  alias_attribute :fund, :MDz_Fund
  alias_attribute :member, :MDz_Member
  alias_attribute :member_number, :MDz_Member
  alias_attribute :group, :MDz_Group
  alias_attribute :category, :MDz_Category 
  alias_attribute :payroll, :MDz_Payroll
  alias_attribute :joined_fund, :MDd_Joined_Fund
  alias_attribute :status, :MDz_Status
  alias_attribute :working_status, :MDc_Working_Status
  #alias attribute :effective_date, :WSd_Effective

    alias_attribute :identity, :MDi_Identity

  def self.get(member_no)
    a_member = Member.where(:MDz_Member => member_no).first
  end
  
  def is_acurity_new_record?
    self.member.blank?
  end
  
  def name
    "#{given_names.strip} #{surname.strip}".strip
  end
  
  def personalise(effective_date, yes_or_no = 'Y', record_type = nil)
    ms = self.member_supplementry_histories.first
    if ms.nil?
      ms = MemberSupplementHistory.new
      ms.record_type ||= record_type
    end
    ms.member = self      
    ms.client = self.client
    ms.personalised_flag = yes_or_no
    ms.effective_date = effective_date
    ms.save
  end
  
  
  def permanent_opt_in(effective_date, yes_or_no = 'Y', record_type = nil)
    ms = self.member_supplementry_histories.first
    if ms.nil?
      ms = MemberSupplementHistory.new
      ms.record_type = record_type
    end
    ms.member = self    
    ms.client = self.client  
    ms.opt_in_flag = yes_or_no
    ms.effective_date = effective_date
    ms.save
  end
  

  private
  
      
  def acurity_create
    if !self.member.blank?
      # puts("\n[DEBUG] skipping calling server already has member")
      return
    end
    
    resp_xml, req_xml = AcurityWebservice::invoke_ws("addMember00001", {:member => self}, {:debug => $SHOW_WS_MSG} )
    doc = Nokogiri::XML resp_xml
    doc.remove_namespaces!
    
    the_member_number = doc.xpath("//addMember00001Response/return").first.text 
    self.member = the_member_number
    return the_member_number    
  end
  
  def acurity_update    
    AcurityWebservice::invoke_ws("updateMemberDetails00001", {:member => self}, {:debug => $SHOW_WS_MSG, :dry_run => false} )
  end  
  
end
