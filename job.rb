class BannedWordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    for term in BannedWord.list
      if value.index(/(^|\s)#{term}(\s|$)/i)
        record.errors[attribute] << 'has banned words. Please remove any content that goes against the Terms of Service.' 
        return true
      end
    end
    false
  end
end

module Tire
  module Model
    module Naming
      module ClassMethods
        def document_type name=nil
          @document_type = name if name
          @document_type || klass.model_name.underscore.split("/")[0]
          #@document_type || klass.model_name.underscore.gsub("/","_")
        end
      end
    end
  end
end

class Job < ActiveRecord::Base
  # See also Job::Craigslist and Job::Temphunt

  has_many :worker_job_applied_mappings
  has_many :applied_workers, :through =>:worker_job_applied_mappings,:source=>:worker
  #has_many :websites
  has_many :interests
  has_many :interested_workers, :through => :interests, :source => :worker
  has_one :location, :class_name => "JobLocation",  :foreign_key => "belongs_to_id", :dependent => :destroy

  has_many :skills,  :as => :skill_target, :dependent => :destroy
  has_many :questions,:class_name => "InterviewQuestion", :dependent => :destroy
  
  has_many :worker_visited_job_mappings
  has_many :visited_workers, :through =>:worker_visited_job_mappings,:source=>:worker
  
  has_many :spams
  has_many :job_spam_workers, :through =>:spams
  
  has_many :worker_hidden_job_mappings
  has_many :hided_job_workers, :through =>:worker_hidden_job_mappings,:source => :worker
  has_many :worker_bookmarked_job_mappings
  has_many :bookmarked_workers, :through =>:worker_bookmarked_job_mappings,:source => :worker

  ## Validations (only common to all types of job)
  validates :title, :description, :presence => true, :banned_word => false
  
  
  validate :job_description,:on=>:update 

  
  def job_description 
    self.errors.add("",I18n.t('presence_of_description')) if description.present? && description.strip_tags.blank?
  end
  
  validate :maximum_questions

  def maximum_questions
    self.errors.add("", I18n.t('job_interview_question_validation')) if self.questions.length > 5
  end
  
  before_create :set_expiration_date
  # before_save :set_end_date

  paginates_per 10 #PER_PAGE=10

  attr_accessible :title, 
    :description, 
    :keywords, 
    :rate, 
    :company, 
    :more_info_url, 
    :avatar, 
    :skills_attributes,
    :questions_attributes,
    :location_attributes,
    :general_help,
    :telecommuting,
    :address,
    :job_employment_type_id
    
              
                  
  accepts_nested_attributes_for :skills,:questions,:location, :reject_if => :all_blank, :allow_destroy => true
  # attr_accessible :websites_attributes
  # accepts_nested_attributes_for :websites, :allow_destroy => true
  attr_accessor :job_location,:job_type,:job_avatar_url #Creating this accessor to access the Uncomman attributes of jobs from SimplyHired and Indeed 

#### TIRE START
include Tire::Model::Search
include Tire::Model::Callbacks

#### Code to debug the Tire Callbacks function
# after_save    :update_elasticsearch_index
# after_destroy :update_elasticsearch_index
# def update_elasticsearch_index
#   binding.pry
#   tire.update_index
# end

tire do
  mapping do
    indexes :coordinates, type: 'geo_point'
    indexes :company, :analyzer => 'simple'
    indexes :description, :analyzer => 'snowball'
    indexes :title, boost: 5, :analyzer => 'snowball'
    indexes :keywords, boost: 5, :analyzer => 'whitespace'
    indexes :skills_name, boost: 10, :analyzer => 'whitespace'
    indexes :general_help, type: 'boolean'
    indexes :telecommuting, type: 'boolean'
    indexes :expires_at, type: 'date'
    indexes :updated_at, type: 'date'
  end
end

#### Search to find jobs that match the 
# query: search term or terms, should be a single string 
# params: used for page number etc..
# user: if user is provided, search result will match his preferences
def self.search_by_skills(query, params, user = nil)
  tire.search(load: true, page: (params[:page] || 1)) do |t|
    if query.present?
      t.query { string query} #, default_operator: "AND"
      if user
        t.filter :geo_distance, coordinates: user.locations.first.coordinates, distance: "#{user.locations.first.radius}#{user.distance_unit}" if user.locations.present?
        #t.filter :not , {:term => {telecommuting: "true"}} unless user.remote?
        t.filter :not , {:ids => { :values => user.worker_hidden_job_mappings.map{|x|x.job_id} }} if user.worker_hidden_job_mappings.present?
        if user.skills.blank?
          t.filter :term, general_help: "true" 
        else
          t.filter :term, general_help: "false" unless user.general_help?
        end
      end
    else
      t.sort { by :updated_at, "desc" } 
    end
    t.filter :range, expires_at: {gt: Time.zone.now}
  end
end

def self.search_by_location(query, params, lat_lng)
  tire.search(load: true, page: params[:page]) do |t|
    t.query { string query} #, default_operator: "AND"
    t.filter :geo_distance, coordinates: lat_lng, distance: "60km" if lat_lng.present?
    t.filter :range, expires_at: {gt: Time.zone.now}
  end
end

def to_indexed_json
  #to_json(methods: [:skills_name, :lat_lon])
  to_json(only: ['description','company','title','keywords','general_help','expires_at','updated_at'], methods: ['coordinates','skills_name'])

  # {
  #   description: description,
  #   company: company,
  #   title: title,
  #   keywords: keywords,
  #   general_help: general_help,
  #   skills_name: skills_name,
  #   expires_at: expires_at,
  #   lat_lon: lat_lon
  # }.to_json
end

def skills_name
  skills.map{|x|x.name}.join(" ") unless skills.nil?
end


# def location
#   self.location.coordinates.join(",") if self.location
# end
#TIRE END


  ##Search 
  # include PgSearch
  # pg_search_scope :search_by_all, 
  #   :against => {:company      => 'C', 
  #   :description  => 'B', 
  #   :title        => 'A',
  #   :keywords => 'B'
  # },
  #   :associated_against => {
  #   :location => {:city           => 'B',
  #     :postal_code    => 'B',
  #     :state          => 'C',
  #     :country        => 'C'},
  #   :skills => { :name    => 'A'}
  # }, 
  #   :using => {:tsearch => {:any_word => true, :dictionary => I18n.locale[/^en/].nil? ? "simple": "english" } }

  # pg_search_scope :search_by_skills, 
  #   :against => {:description  => 'D', 
  #   :title        => 'B',
  #   :keywords => 'B'
  # },
  #   :associated_against => {
  #   :skills => { :name    => 'A'}
  # },
  #   :using => {:tsearch => {:any_word => true, :dictionary => I18n.locale[/^en/].nil? ? "simple": "english"}}#,


  #scope :mine,   lambda{|*args|{:conditions => ["user_id = ?", args.first] } }
  scope :open,   lambda{{:conditions => ["expires_at > ?", DateTime.now.utc] }}
  scope :closed, lambda{{:conditions => ["expires_at <= ?", DateTime.now.utc] }}
  scope :recent, :order => "jobs.created_at desc"



 
  if Rails.env.production?
    has_attached_file :avatar, 
      :storage => :s3,
      :s3_credentials => "#{Rails.root}/config/s3.yml",
      :path => "/avatars/jobs/:id/:style/:filename",
      :styles => { 
      :large => "300x300>", 
      :medium => "150x150>", 
      :small => "60x60>", 
      :tiny => "40x40>" 
    }
  else
    has_attached_file :avatar, 
      :path => ":rails_root/public/system/avatars/jobs/:id/:style/:filename",
      :url => "/system/avatars/jobs/:id/:style/:filename",
      :styles => { 
      :large => "300x300>", 
      :medium => "150x150>", 
      :small => "60x60>", 
      :tiny => "45x45>",
      :small_tiny => "40x40>"
    }
  end



  PERMANENT = 'permanent'
  TEMPORARY = 'temporary'
  DURATIONS = [PERMANENT, TEMPORARY]
  INDEED_JOBS = {:url=>"http://api.indeed.com/ads/apisearch",:publisher_key=>"3630055334220752",:type=>"indeed"}
  SIMPLY_HIRED_JOBS = {:url=>"http://api.simplyhired.",:publisher_key=>"37733",:type=>"simply_hired"}
  APPLICABLE = ['start_date','duration','avatar_file_name']
  
  def index_search_action?(params)
    params[:controller].eql?("jobs") && (params[:action].eql?("index") || params[:action].eql?("search")||params[:action].eql?("show"))
  end

  def type?(name)
    name.to_s == self.type_name
  end

  def type_name
    self.type.demodulize.underscore
    #Example: Job::Craigslist -> craigslist
  end
  def self.location_boost
    #Boost for jobs that fall in worker's prefered radius
    1.0
  end
  
  def required_skills
    self.skills.map{|x|x.name}
  end
  
  ## Job location methods
  def address=(string)
    self.build_location(:address => string)
  end
  def address
    self.location.full_address if self.location
  end
  def coordinates
    self.location.coordinates if self.location
  end
  def location_string
    out = nil
    out = self.location.public_address if self.location
    #binding.pry
    out || "Anywhere"
  end

  def open?
    expires_at > DateTime.now if expires_at
  end

  def closed?
    expires_at < DateTime.now if expires_at
  end

  def temporary?
    duration == TEMPORARY
  end

  def permanent?
    duration == PERMANENT
  end

  def headline
    str=""
    str << "#{company}, " unless company.blank?
    str << location_string
  end

  def start_date_string
    start_date.strftime("%A %B #{start_date.day.ordinalize}")
  end

  def end_date_string
    end_date.strftime("%A %B #{end_date.day.ordinalize}")
  end

  # Avatar

  def avatar_image_url(size)
    if self.avatar.file?
      self.avatar.url(size.to_sym)
    else
      "logo/default-avatar-#{size.to_s}.png"
    end
  end
	
  def self.create_job_array(jobs,job_source="local")
    jobs_arr = []
    jobs.each do |job|
      if job_source == "local" 
        job_avatar_url = job.avatar_image_url(:tiny)
        job_location = job.location_string
        job_type = job_source

      elsif job_source == Job::INDEED_JOBS[:type]
        job_id = nil
        job_avatar_url = "default-avatar-tiny-inverse.png" #"indeed.png"
        job_company = job["company"].first
        job_location = "#{job["formattedLocation"].first.to_s}, #{job["country"].first.to_s}"
        job_title = job["jobtitle"].first
        job_type = job_source
        job_created_at=job["date"].first
        job_duration=nil
        job_url = "#{job["url"].first.gsub!("/viewjob","/rc/clk")}&from=vj"
        job_employer = nil

      elsif job_source == Job::SIMPLY_HIRED_JOBS[:type]
        job_id = nil
        job_avatar_url = "default-avatar-tiny-inverse.png" #"simplyhired.png"
        job_company = job["cn"][0]["content"]
        job_location = "#{job["loc"][0]["cty"]}, #{job["loc"][0]["st"]}, #{job["loc"][0]["country"]}"
        job_title = job["jt"].first
        job_type = job_source
        job_created_at=job["dp"].first
        job_duration=job["ty"].first
        job_url = job["src"][0]["url"]
        job_employer = nil
      end
      if job_source == "local" 
        merge_job = job
      else
        merge_job = Job.new(:company=>job_company,:title=>job_title,:created_at=>job_created_at,:duration=>job_duration,:more_info_url=>job_url,:user_id=>job_employer)
      end
      merge_job.job_location = job_location
      merge_job.job_type = job_type
      merge_job.job_avatar_url = job_avatar_url
      jobs_arr << merge_job
    end
    return jobs_arr
  end

  #################################################
  private

  def set_expiration_date #before_create
    self[:expires_at] = 60.days.from_now
  end 

  
  # def set_end_date #before_save
  #   self[:end_date] = nil if self[:duration] == PERMANENT
  # end 

  # SEARCH_PARAMS = [
  # :keywords
  # ]

  # SEARCHABLE = [
  # 'title',         # Title of the post
  # 'description',   # Description of the post
  # 'keywords',      # Keywords or 'skills'
  # 'additional_keywords', # use description and and title as keywords
  # 'company',       # Company name
  # 'locations.name',# Location 
  # 'user.domain'    # Domain
  # ]

  # def title=(input="")
  # self.additional_keywords = "#{input} #{description} #{company}"
  # self[:title] = input
  # end
  # 
  # def description=(input="")
  # self.additional_keywords = "#{input} #{title} #{company}"
  # self[:description] = input
  # end

  # def company=(input="")
  # self.additional_keywords = "#{input} #{title} #{description}"
  # self[:company] = input
  # end

  #
  # Criteria satisfaction
  #
  # def satisfies(criteria)
  # # Assume 0 if satisfies_x not implemented
  # if methods.include?("satisfies_#{criteria.name}")
  # self.send("satisfies_#{criteria.name}", criteria.value).to_f
  # else
  # 0
  # end
  # end

  # def satisfies_domain(value)
  # self.user.domain == value ? 1.0 : 0.0
  # end

  # def satisfies_keywords(value)
  # # Semantics of no keywords entered is that everyone matches
  # return 1 if ["","Enterkeywords"].include?(value.to_s)
  # return 0 if self.keywords.empty?

  # union = lambda do |a, b|
  # a ||= []
  # b ||= []
  # results = a.map do |s|
  # b.grep(Regexp.new(Regexp.quote(s), true)).reject do |i|
  # s.length < (i.length.to_f / 2) # If less then half of the word matched, drop it
  # end
  # end + b.map do |s|
  # a.grep(Regexp.new(Regexp.quote(s), true)).reject do |i|
  # s.length < (i.length.to_f / 2) # If less then half of the word matched, drop it
  # end
  # end
  # results.flatten.uniq
  # end
 
  # additional_keyword_weight = union.call(self.additional_keywords, value).length > 0 ? 0.25 : 0.0

  # union.call(self.keywords, value).length.to_f / self.keywords.length + additional_keyword_weight
  # end

  # def desirability
  # # Find out how much of the profile
  # # was filled in. `nil` values are
  # # not acceptable, `false` is ok.
  # fields = (APPLICABLE + SEARCHABLE).reject{|field|field.include?(".")}
  # fields.reject do |field|
  # self.send(field).nil?
  # end.length.to_f / fields.length
  # end
end
