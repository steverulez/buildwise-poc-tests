require File.dirname(__FILE__) + '/acurity_webservice.rb'

# Set up model classes
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  if defined?(TestWiseRuntimeSupport)  # TestWise 5
    include TestWiseRuntimeSupport
  end
  
  def save(opts = {})
    if defined?(TestWiseRuntimeSupport) 
      dump_caller_stack
    end
      
    if is_acurity_new_record? 
      acurity_create
    else
      acurity_update
    end
  end
  
  def is_acurity_new_record? 
    self.identity.blank?
  end
  
  
  def self.find_by_identity(an_identity) 
    where(:identity => an_identity).first
  end
  
  def self.padding_client_no(a_no)
    the_padded = a_no.rjust(13, " ").ljust(17, " ")
    return the_padded
  end
  
end
