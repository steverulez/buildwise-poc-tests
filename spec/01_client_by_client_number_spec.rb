load File.dirname(__FILE__) + "/../test_helper.rb"
load File.dirname(__FILE__) + "/../database_test_helper.rb"

describe "Create Client" do
  include TestHelper
  include DatabaseTestHelper

  before(:all) do
    $SHOW_WS_MSG = true

    # 1. the scripts can work with different server
    #     connect_database("DEV01")
    # or
    #     using the statement below to flexiably set by an environment variable "SERVER"
    
    #{"ALLUSERSPROFILE"=>"C:\\ProgramData", "APPDATA"=>"C:\\Users\\zhzhan\\AppData\\Roaming", "COLUMNS"=>"120", "CommonProgramFiles"=>"C:\\Program Files\\Common Files", "CommonProgramFiles(x86)"=>"C:\\Program Files (x86)\\Common Files", "CommonProgramW6432"=>"C:\\Program Files\\Common Files", "COMPUTERNAME"=>"R90R5XKW", "ComSpec"=>"C:\\WINDOWS\\system32\\cmd.exe", "DriverData"=>"C:\\Windows\\System32\\Drivers\\DriverData", "HOME"=>"C:/Users/zhzhan", "HOMEDRIVE"=>"C:", "HOMEPATH"=>"\\Users\\zhzhan", "LINES"=>"9001", "LOCALAPPDATA"=>"C:\\Users\\zhzhan\\AppData\\Local", "LOGONSERVER"=>"\\\\SRVDCGPR01", "NUMBER_OF_PROCESSORS"=>"8", "OneDrive"=>"C:\\Users\\zhzhan\\OneDrive", "OS"=>"Windows_NT", "Path"=>"C:\\Program Files (x86)\\Pervasive Software\\PSQL\\bin\\;C:\\Program Files (x86)\\Common Files\\Oracle\\Java\\javapath;C:\\WINDOWS\\system32;C:\\WINDOWS;C:\\WINDOWS\\System32\\Wbem;C:\\WINDOWS\\System32\\WindowsPowerShell\\v1.0\\;C:\\WINDOWS\\System32\\OpenSSH\\;C:\\Program Files\\Intel\\WiFi\\bin\\;C:\\Program Files\\Common Files\\Intel\\WirelessCommon\\;C:\\Program Files (x86)\\Enterprise Vault\\EVClient\\;C:\\Program Files (x86)\\Microsoft SQL Server\\Client SDK\\ODBC\\130\\Tools\\Binn\\;C:\\Program Files (x86)\\Microsoft SQL Server\\140\\Tools\\Binn\\;C:\\Program Files (x86)\\Microsoft SQL Server\\140\\DTS\\Binn\\;C:\\Program Files (x86)\\Microsoft SQL Server\\140\\Tools\\Binn\\ManagementStudio\\;C:\\Ruby26-x64\\bin;C:\\Ruby25-x64\\bin;C:\\Users\\zhzhan\\AppData\\Local\\Microsoft\\WindowsApps;C:\\Users\\zhzhan\\AppData\\Local\\Programs\\Git\\cmd;C:\\Users\\zhzhan\\AppData\\Local\\Programs\\Microsoft VS Code\\bin", "PATHEXT"=>".COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC", "PROCESSOR_ARCHITECTURE"=>"AMD64", "PROCESSOR_IDENTIFIER"=>"Intel64 Family 6 Model 142 Stepping 10, GenuineIntel", "PROCESSOR_LEVEL"=>"6", "PROCESSOR_REVISION"=>"8e0a", "ProgramData"=>"C:\\ProgramData", "ProgramFiles"=>"C:\\Program Files", "ProgramFiles(x86)"=>"C:\\Program Files (x86)", "ProgramW6432"=>"C:\\Program Files", "PROMPT"=>"$P$G", "PSModulePath"=>"C:\\Program Files\\WindowsPowerShell\\Modules;C:\\WINDOWS\\system32\\WindowsPowerShell\\v1.0\\Modules", "PUBLIC"=>"C:\\Users\\Public", "SESSIONNAME"=>"Console", "snow_agent"=>"C:\\Program Files\\Snow Software\\Inventory\\Agent", "SystemDrive"=>"C:", "SystemRoot"=>"C:\\WINDOWS", "TEMP"=>"C:\\Users\\zhzhan\\AppData\\Local\\Temp", "TMP"=>"C:\\Users\\zhzhan\\AppData\\Local\\Temp", "UATDATA"=>"C:\\WINDOWS\\CCM\\UATData\\D9F8C395-CAB8-491d-B8AC-179A1FE1BE77", "USER"=>"zhzhan", "USERDNSDOMAIN"=>"GSO.INTERNAL", "USERDOMAIN"=>"GSO", "USERDOMAIN_ROAMINGPROFILE"=>"GSO", "USERNAME"=>"zhzhan", "USERPROFILE"=>"C:\\Users\\zhzhan", "windir"=>"C:\\WINDOWS"}.each do |key, val|
       #ENV[key] = val
    #end
    #
    # File.open("C:/agileway/tmp/tw-run.log","a").write(ENV.inspect)
    connect_database
  end

  after(:all) do
  end

  it "[T01] Get a client from Acurity by client number" do
    # Get a client from Acurity Database, store a varaible (to check data)
    # the above will get data, to use it, need to store to a variable
    test_client = Client.get("195462113")
    puts(test_client.inspect)  # print out the client data
  end

  it "[T02] Get client datail" do
    test_client = Client.get("195447305")
    # get client specific attributes
    # useful for verification or pass to other scripts
    puts test_client.surname
    puts test_client.title

=begin
  alias_attribute :client_number, :D2z_Client
  alias_attribute :surname, :D2z_Surname_Upp
  alias_attribute :given_names, :D2z_Given_Names_Upp
  alias_attribute :title, :D2z_Title
  alias_attribute :marital_status, :D2z_Marital_Status
  alias_attribute :birth, :D2d_Birth
  alias_attribute :birth_place, :D2z_Birth_Place
  alias_attribute :email, :D2z_Email
  alias_attribute :state, :D2z_State
  alias_attribute :sex, :D2z_Sex
  alias_attribute :occupation, :D2z_Occupation
  alias_attribute :smoker, :D2c_Smoker
  alias_attribute :country, :D2z_Country
  alias_attribute :mobile_phone, :D2z_Mobile_Phone
  alias_attribute :home_phone, :D2z_Home_Phone
  alias_attribute :work_phone, :D2z_Work_Phone
  alias_attribute :post_code, :D2z_Post_Code
  alias_attribute :country_code, :D2z_Country_Code
  alias_attribute :identity, :D2i_Identity	
=end
  end
  

end
