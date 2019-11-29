load File.dirname(__FILE__) + "/../test_helper.rb"
load File.dirname(__FILE__) + "/../database_test_helper.rb"

describe "Create and Update Member " do
  include TestHelper
  include DatabaseTestHelper

  before(:all) do
    $SHOW_WS_MSG = true
    connect_database
  end

  after(:all) do
  end

  it "[T31] Create client and member in separate steps" do
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

  it "Update member working status" do
    member_data = { joined_fund: "2018-07-01", payroll: "031000", status: "C", category: "AP", working_status: "C" }
    client_number, member_number = create_client({}, member_data)
    puts "New Client: #{client_number} Member: #{member_number}"

    client= Client.get(client_number)
    member = client.members.first
    
    # the below does not work, as updateMember001 does not include working_status field.
    #member.working_status = "W"
    #member.save

    member_identity = member.identity
    expect(member.working_status).to eq("C")

    # thanks for Ben, we can do this by doJob.
    ws_response = do_job("V001", :member_number => member.member_number, :effective_date => "10/08/2019", :working_status => "W")
    puts ws_response
    
    member = Member.find_by_identity(member.identity)
    expect(member.working_status).to eq("W")
  end
end
