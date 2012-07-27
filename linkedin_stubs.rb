module LinkedinStubs

  def fixture(name)
    File.new("#{Rails.root}/spec/fixtures/#{name}")
  end

  def stub_oauth_request_token!
    stub_request(:post, "https://api.linkedin.com/uas/oauth/requestToken").to_return(:body =>"oauth_token=t&oauth_token_secret=s")
  end

  def stub_oauth_access_token!
#Valid authentic access token value
    stub_request(:post, "https://api.linkedin.com/uas/oauth/accessToken").to_return(:body =>"oauth_token=b346e8fe-acea-4b73-af44-86dc87a426e5&oauth_token_secret=fa14fbe1-bc30-4763-b457-7231dc6b4b90")
  end

  def stub_request_profile!
  stub_request(:get,"https://api.linkedin.com/v1/people/~:(headline,summary,positions,educations,skills,twitter-accounts,member-url-resources,picture-url,public-profile-url,specialties)").to_return(:status => 200, :body =>fixture("linked_in_profile.json"), :headers => {})
  end

end


