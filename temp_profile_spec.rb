require 'spec_helper'

describe "TempProfile" do
  before do
    WebMock.disable_net_connect!(:allow_localhost => true)
    login(:worker)
    app.default_url_options={:locale =>:en }
    visit my_account_path
  end

  
  it "should be able to edit the profile" do
    click_link"Edit"
    current_path.should eq(edit_account_path)
    fill_in "worker_headline", :with =>"TempProfile"
    click_button"Save Changes"
    page.should have_xpath("//div[@class='alert notice']") #Accout Updated
    current_path.should eq(my_account_path)
  end
  
  it "should work the cancel and view profile link" do    #no need to test for each partial
    click_link"Edit"
    current_path.should eq(edit_account_path)
    click_link"Cancel and view profile"
    current_path.should eq(my_account_path)
  end

  describe "Skills" do
    it "should show the validation message skills can not ne blank",:js => true do    
      click_link"Edit Skills"
      current_path.should eq(edit_account_path+"/skills")
      page.should have_link("Add a skill")
      click_link"Add a skill"
      click_button"Save Changes"
      page.should have_xpath("//div[@class='errorExplanation']") #skills can not be blank
    end
  
    it "should show the validation message if no skills apart from novice ",:js => true do
      click_link"Edit Skills"
      current_path.should eq(edit_account_path+"/skills")
      page.should have_link("Add a skill")
      click_link"Add a skill"
      webdriver = page.driver.instance_eval("@browser")
      webdriver.execute_script("$('input[id*=_skill]').val('ruby on rails')")
      click_button"Save Changes"
      page.should have_xpath("//div[@class='errorExplanation']") #atleast apart from novice
    end

    it "should be able to Add a skill ",:js => true do
      click_link"Edit Skills"
      current_path.should eq(edit_account_path+"/skills")
      page.should have_link("Add a skill")
      click_link"Add a skill"
      webdriver = page.driver.instance_eval("@browser")
      webdriver.execute_script("$('input[id*=_skill]').val('ruby on rails')")
      webdriver.execute_script("$('select[id*=_skills] option[value=3]').attr('selected', 'selected')")
      click_button"Save Changes"
      page.should have_xpath("//div[@class='alert notice']") #atleast apart from novice
    end
  end
  
  describe "Experience" do

    it "should show the validation message past jobs title can not ne blank",:js => true do
      click_link"Edit Experience"
      current_path.should eq( edit_account_path+"/past_jobs")
      page.should have_link("Add a job")
      click_link"Add a job"
      click_button"Save Changes"
      page.should have_xpath("//div[@class='errorExplanation']") #skills can not be blank
    end
  
    it "should be able to Add a job ",:js => true do
      click_link"Edit Experience"
      current_path.should eq( edit_account_path+"/past_jobs")
      page.should have_link("Add a job")
      click_link"Add a job"
      webdriver = page.driver.instance_eval("@browser")
      webdriver.execute_script("$('input[id*=_title]').val('Project Manager')")
      webdriver.execute_script("$('input[id*=_company_name]').val('Microsoft Company')")
      click_button"Save Changes"
      current_path.should eq(my_account_path)
      page.should have_content("Project Manager")
    end
  
  end
 
  describe "Education" do
    it "should show the validation message School name can not ne blank",:js => true do
      click_link"Edit Education"
      current_path.should eq( edit_account_path+"/schools")
      page.should have_link("Add a school")
      click_link"Add a school"
      click_button"Save Changes"
      page.should have_xpath("//div[@class='errorExplanation']") 
    end
  
    it "should be able to Add a school",:js => true do
      click_link"Edit Education"
      current_path.should eq( edit_account_path+"/schools")
      page.should have_link("Add a school")
      click_link"Add a school"
      webdriver = page.driver.instance_eval("@browser")
      webdriver.execute_script("$('input[id*=_school]').val('saket shishu ranjan higher secondary')")
      click_button"Save Changes"
      current_path.should eq(my_account_path)
    end
  end


  describe "Websites" do
    it "should be able to Add a websites",:js => true do
      click_link"Edit Websites"
      current_path.should eq( edit_account_path+"/websites")
      page.should have_link("Add a website")
      click_link"Add a website"
      fill_in "worker_facebook", :with =>"www.facebook.com/worker"
      click_button"Save Changes"
      page.should have_link("Facebook")
    end
  end


  describe "Avaliblity" do

    it "should show the validation message event name can not ne blank",:js => true do
      click_link"Edit Availability"
      current_path.should eq( edit_account_path+"/availability")
      page.should have_link("Add an event")
      click_link"Add an event"
      click_button"Save Changes"
      page.should have_xpath("//div[@class='errorExplanation']")
    end
  
    it "should be able to Add a Event ",:js => true do
      click_link"Edit Availability"
      current_path.should eq( edit_account_path+"/availability")
      page.should have_link("Add an event")
      click_link"Add an event"
      webdriver = page.driver.instance_eval("@browser")
      webdriver.execute_script("$('input[id*=_name]').val('meeting')")
      click_button"Save Changes"
      current_path.should eq(my_account_path)
    end

  end


end
