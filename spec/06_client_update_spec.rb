load File.dirname(__FILE__) + "/../test_helper.rb"
load File.dirname(__FILE__) + "/../database_test_helper.rb"

describe "Client Update" do
  include TestHelper
  include DatabaseTestHelper

  before(:all) do
    # $SHOW_WS_MSG = true
    connect_database    
  end

  after(:all) do
  end

  #
  it "[T26] Update Client basic information" do    
    client_number, member_number = create_client({}, nil) # create a new client and member
    puts("New client: #{client_number}, Member: #{member_number}")
    client = Client.get(client_number)
    puts ("client birth place: #{client.birth_place}")
    client.birth_place = "Newmarket"
    client.email="testuser001@ztest.com"
    # will just update, the same function call create in Acurity DB 
    client.save
        
    db_client = Client.get(client_number)
    expect(db_client.birth_place.strip).to eq("Newmarket")
    expect(db_client.email.strip).to eq("testuser001@ztest.com")
  end

  it "[T27] Update Policy Benefit Details" do    
    client_data = { birth: Faker::Date.between(from: 22.years.ago, to: 63.years.ago).to_s }
    member_data = { joined_fund: Faker::Date.between(from: 30.days.ago, to: 10.days.ago).to_s,
                    category: "AP",
                    working_status: "P" }
    puts(member_data.inspect)
    client_number, member_number = create_client_with_policy(client_data, member_data)
    
    puts("New client: #{client_number}, Member: #{member_number}")

    client = Client.get(client_number)
    policy_benefit_details = client.first_policy_benefit_of("D ")
    puts "Before Occuption: #{policy_benefit_details.occupation}"
    puts "Before status: #{policy_benefit_details.status}"
    policy_benefit_details.occupation = "2"
    policy_benefit_details.save
    
    client = Client.get(client_number)
    policy_benefit_details = client.first_policy_benefit_of("D ")
    puts "After Occuption: #{policy_benefit_details.occupation}"
    expect(policy_benefit_details.occupation).to eq("2 ")
  end

end
