#require 'factory_girl'
require 'faker'

module FactoryHelper
  COMPANIES = %w[Ubisoft Google SquareSpace Facebook FourSquare]
  LOCATIONS = ['The Bronx', 'Queens', 'Montreal', 'Manhattan', 'Toronto', 'Vancouver']
  KEYWORDS = %w[carpenter ruby javascript driver cook developer receptionist]
  ADJECTIVES = %w[experienced student]
  RANDOM_KEYWORDS = [
    %w[secretary office hard work organized],
    %w[programmer problem solver javascript ruby],
    %w[landscaping ciment garden yard work flowers],
    %w[trucker transportation courier delivery],
    %w[pet sitter cats dogs],
    %w[developer c++ asp],
    %w[driver truck mover]
    #%w[] #Keywords cannot be blank in the job
  ]



  class << self
    def randomize(array)
      array[rand(array.size)]
    end
    def random_title
      random_headline
    end

    def random_company
      randomize(COMPANIES)
    end

    def random_location
      randomize(LOCATIONS)
    end

    def random_headline
      [randomize(ADJECTIVES), randomize(KEYWORDS)].join(' ')
    end

    def random_keywords
      randomize(RANDOM_KEYWORDS)
    end

    def random_availability
      # A random length block
      # Placed randomly in the day
      # every day
      block_length = 2 + rand(6)
      block        = ("1" * block_length).to_i(2)
      max_offset   = 24 - block_length

      return block << rand(max_offset)
    end

    def random_week
      7.times.to_a.inject(0) do |sum, i|
        sum | (random_availability << i * 24)
      end
    end
  end
end

Factory.define :user do |u|
  u.first_name   { Faker::Name.first_name }
  u.last_name   { Faker::Name.last_name }
  #u.login        {|u| [u.first_name, u.last_name].join('_').gsub(/[^0-9a-zA-Z\.-_@]/i, '') } #Some names in faker have ' in them which break tests
  u.headline     {|u| FactoryHelper.random_headline }
  u.keywords     { FactoryHelper.random_keywords }
  #u.password     {|u| u.login }
  u.password     {|u| "#{u.first_name}#{u.last_name}"}
  #u.password_confirmation {|u| u.login }
  u.password_confirmation {|u| "#{u.first_name}#{u.last_name}" }
  #u.email        {|u| "#{u.login}@gmail.com" }
  u.email        {|u| "#{u.first_name}#{u.last_name}@gmail.com" }
  u.active       true
  u.availability { FactoryHelper.random_week }
  u.available_as_of {|u| FactoryHelper.randomize([nil, Date.yesterday.to_s, Date.tomorrow.to_s])}
  u.remote       {|u| FactoryHelper.randomize([true, false, nil]) }
  u.fulltime     {|u| FactoryHelper.randomize([true, false, nil]) }
  u.rate         {|u| FactoryHelper.randomize([9.25, 10.50, 14.00, 7.00, 50.00, nil]) }
  #u.gender       {|u| FactoryHelper.randomize(['male', 'female', nil]) }
  #u.twitter      {|u| FactoryHelper.randomize(["http://www.twitter.com/#{u.login}", nil]) }
  #u.facebook     {|u| FactoryHelper.randomize(["http://www.facebook.com/#{u.login}", nil]) }
  #u.linkedin     {|u| FactoryHelper.randomize(["http://www.linkedin.com/#{u.login}", nil]) }
  u.twitter      {|u| FactoryHelper.randomize(["http://www.twitter.com/#{u.first_name}", nil]) }
  u.facebook     {|u| FactoryHelper.randomize(["http://www.facebook.com/#{u.first_name}", nil]) }
  u.linkedin     {|u| FactoryHelper.randomize(["http://www.linkedin.com/in/#{u.first_name}", nil])}
  u.domain       {|u| FactoryHelper.randomize(['temphunt.com', 'temphunt.ca']) }
	#Added this attribute to determine the type of user when testing
	u.confirmed_at { FactoryHelper.randomize(["2011-11-03 10:19:12.815997","2011-11-03 10:19:12.815997"])}
	u.type				 {|u| FactoryHelper.randomize(['Worker', 'Employer']) }

end

Factory.define :worker do |u|
  u.first_name   { Faker::Name.first_name }
  u.last_name   { Faker::Name.last_name }
  #u.login        {|u| [u.first_name, u.last_name].join('_').gsub(/[^0-9a-zA-Z\.-_@]/i, '') } #Some names in faker have ' in them which break tests
  u.headline     {|u| FactoryHelper.random_headline }
  u.keywords     { FactoryHelper.random_keywords }
  u.password     {|u| "#{u.first_name}#{u.last_name}"}
  u.password_confirmation {|u| "#{u.first_name}#{u.last_name}" }
  u.email        {|u| "#{u.first_name}#{u.last_name}@gmail.com" }
  u.active       true
  u.availability { FactoryHelper.random_week }
  u.available_as_of { FactoryHelper.randomize([nil, Date.yesterday.to_s, Date.tomorrow.to_s])}
  u.remote       { FactoryHelper.randomize([true, false, nil]) }
  u.fulltime     { FactoryHelper.randomize([true, false, nil]) }
  u.rate         { FactoryHelper.randomize([9.25, 10.50, 14.00, 7.00, 50.00, nil]) }
  #u.gender       { FactoryHelper.randomize(['male', 'female', nil]) }
  u.twitter      {|u| FactoryHelper.randomize(["http://www.twitter.com/#{u.first_name}", nil]) }
  u.facebook     {|u| FactoryHelper.randomize(["http://www.facebook.com/#{u.first_name}", nil]) }
  u.linkedin     {|u| FactoryHelper.randomize(["http://www.linkedin.com/in/#{u.first_name}", nil]) }
  u.domain       { FactoryHelper.randomize(['temphunt.com', 'temphunt.ca']) }
	#Added this attribute to determine the type of user when testing
	u.confirmed_at { FactoryHelper.randomize(["2011-11-03 10:19:12.815997","2011-11-03 10:19:12.815997"])}
	u.type				 { 'Worker' }
end

Factory.define :employer do |u|
  u.first_name   { Faker::Name.first_name }
  u.last_name   { Faker::Name.last_name }
  u.password     {|u| "#{u.first_name}#{u.last_name}" }#Becuase somtimes password is too short (atleast 6 char should be)
  u.password_confirmation {|u| "#{u.first_name}#{u.last_name}" }
  u.email        {|u| "#{u.first_name}#{u.last_name}@gmail.com" }
  u.type         { 'Employer' }
  u.company_name      { Faker::Company.name}
  u.address   { Faker::Address.street_address}
  u.zipcode  12345
  u.phone     "(555) 555-5555"
  u.company_industry  { FactoryHelper.randomize(["Landscaping", "Software Engineering", "Pharmaceuticals"])}
  u.company_employees { FactoryHelper.randomize((5..100).to_a) }
  # u.association :job, :factory => :job
	u.active       true
	u.confirmed_at { FactoryHelper.randomize(["2011-11-03 10:19:12.815997","2011-11-03 10:19:12.815997"])}
end

Factory.define :contact_request do |cr|
  cr.name  {"#{Faker::Name.first_name} #{Faker::Name.last_name}"}
  cr.email {|r| "someemail@gmail.com" }
  cr.subject "Some Subject"
  cr.message {Faker::Lorem.paragraph(3)}
end

Factory.define :job,:class=>"Job::Temphunt" do |j|
  j.rate        { FactoryHelper.randomize([9.25, 10.50, 14.00, 7.00, 50.00, nil]) }
  j.title       { FactoryHelper.random_title }
  j.description { Faker::Lorem.paragraph(3) }
  j.keywords    { FactoryHelper.random_keywords }
  j.company     { FactoryHelper.random_company }
  j.duration    { FactoryHelper.randomize(['permanent','temporary']) }
  j.association :employer, :factory => :employer
  j.association :employment_type, :factory => :job_employment_type
end

Factory.define :location, :class => "WorkerLocation"do |l|
  l.address { FactoryHelper.random_location }
  l.association :worker, :factory => :worker
end

Factory.define :interest do |l|
  #l.address { FactoryHelper.random_location }
	l.association :job, :factory => :job
	l.association :worker, :factory => :worker
end


Factory.define :job_employment_type do |l|
  l.value { FactoryHelper.randomize(['Full Time','Part Time','Project','Hourly','Seasonal','Temporary','Internship']) }
end


#Add a one free credit for test
Factory.define :product do |l|
  l.special "TRUE"
  l.name "1 credit"
  l.price {0.0}
  l.credit_value {1}
end

