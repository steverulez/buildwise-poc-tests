load File.dirname(__FILE__) + "/../test_helper.rb"
load File.dirname(__FILE__) + "/../database_test_helper.rb"

describe "Create Client" do
  include TestHelper
  include DatabaseTestHelper

  before(:all) do
    $SHOW_WS_MSG = false
    connect_database
  end

  after(:all) do
  end

  # 3. create_default_client will create a new client
  #    non specificed data will be randomly generated 
  #
  ## Some default values
  #
  # birth_place = "TEST AUTOMATION FARM"
  # state = "QLD"
  # post_code = "4000"
  # birth_date => (21 to 60 years)
  # all phones => "0438492160"
  # email =>"Project_testemail@qsuper.qld.gov.au"
  #
  # member_category = "AP"
  # fund = "GSUP"
  # payroll = "031000"
  # status = "C"
  # joined_fund => (3 years to 1 years aga)
  #
  it "[T05] Create a new random client with member" do
    client_number, member_number = create_client()
    puts "New Client: #{client_number}, Member: #{member_number}"
  end

  it "[T06] Create a new random client without member" do
    client_number, member_number = create_client({}, nil)
    puts "New Client: #{client_number}"
    client = Client.get(client_number)
    puts("Surname: #{client.surname}")
    puts("Given: #{client.given_names}")
    puts("Birth: #{client.birth}")
  end

  it "[T07] Create a new client with specific attributes" do
    client_data = { surname: "Zmith", birth: "1987-06-18", sex: "M", marital_status: "W" }
    client_number, member_no = create_client(client_data, nil)
    test_client = Client.get(client_number)
    expect(test_client.surname.strip).to eq("ZMITH") # strip remove spaces
  end

  it "[T08] Create client and member in separate steps" do
    surname = Faker::Name.last_name.upcase
    first_name = Faker::Name.first_name.upcase
    client = Client.new(
      :surname => surname,
      :given_names => first_name,
      :birth => Faker::Date.between(from: 60.years.ago, to: 21.years.ago),
      :sex => ["M", "F"].sample,
      :marital_status => ["D", "M", nil].sample,
      :email => Faker::Internet.email,
      :birth_place => "TEST AUTOMATION FARM",
      :title => Faker::Name.prefix.gsub(".", "").upcase,    # Mrs. => MRS
      :state => "QLD",
    )

    new_client_no = client.save # will create one in Acurity
    puts("New client #{first_name} #{surname} => #{client.client_number}")

    # connecting two objects by "client_number"
    member = Member.new(:fund => "GSUP", :payroll => "031000", :category => "AP",
                        :client_number => client.client_number, :joined_fund => Faker::Date.between(from: 3.years.ago, to: 1.years.ago),
                        :status => "E")
    member.save
    new_member_number = member.member
    puts("New member number => #{new_member_number}")
  end

  it "[T09] Create a new client with member attributes" do
    member_data = { joined_fund: "2018-07-01", payroll: "031000", status: "C", category: "AP", working_status: "C" }
    client_number, member_number = create_client({}, member_data)
    puts "New Client: #{client_number}, Member: #{member_number}"
  end

  it "[T10] Create new client, member with faker and dynamic data" do
    surname = Faker::Name.last_name.upcase
    birth_date = 25.years.ago
    joined_fund_date = Date.yesterday
    client_data = { surname: surname, birth: birth_date.to_s, sex: "M", marital_status: "W" }
    member_data = { joined_fund: joined_fund_date.to_s, payroll: "031000", status: "C", category: "AP", working_status: "C" }
    client_number = create_client(client_data, member_data)
  end
end
