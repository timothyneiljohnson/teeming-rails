class Race < ApplicationRecord
  belongs_to :election
  has_many :candidacies, dependent: :destroy
  has_one  :questionnaire, as: :questionnairable
  belongs_to  :created_by_user, class_name: 'User', foreign_key: 'created_by_user_id'
  belongs_to  :updated_by_user, class_name: 'User', foreign_key: 'updated_by_user_id'

  validates :name, presence: true,                if: ->{ election.internal? }
  validates :level_of_government, presence: true, if: ->{ election.external? }
  validates :locale, presence: true,              if: ->{ election.external? }

  scope :active_for_time, ->(time){ where(Race.arel_table[:filing_deadline_date].gt(time) ) }
  scope :by_last_update, ->{  order("updated_at desc") }

  LEVEL_OF_GOVERNMENT_TYPE_SCHOOL_BOARD =           'school_board'
  LEVEL_OF_GOVERNMENT_TYPE_MAYOR =                  'mayor'
  LEVEL_OF_GOVERNMENT_TYPE_CITY_COUNCIL =           'city_council'
  LEVEL_OF_GOVERNMENT_TYPE_COUNTY_COMMISSIONER =    'county_commissioner'
  LEVEL_OF_GOVERNMENT_TYPE_COUNTY_PROSECUTOR =      'county_prosecutor'
  LEVEL_OF_GOVERNMENT_TYPE_SHERIFF =                'sheriff'
  LEVEL_OF_GOVERNMENT_TYPE_STATE_REPRESENTATIVE =   'state_representative'
  LEVEL_OF_GOVERNMENT_TYPE_STATE_SENATOR =          'state_senator'
  LEVEL_OF_GOVERNMENT_TYPE_STATE_AUDITOR =          'state_auditor'
  LEVEL_OF_GOVERNMENT_TYPE_SECRETARY_OF_STATE =     'secretary_of_state'
  LEVEL_OF_GOVERNMENT_TYPE_CONGRESSPERSON =         'congressperson'
  LEVEL_OF_GOVERNMENT_TYPE_SENATOR =                'senator'
  LEVEL_OF_GOVERNMENT_TYPE_GOVERNOR =               'govenor'

  LEVEL_OF_GOVERNMENT_TYPES = {
      "School Board" =>         LEVEL_OF_GOVERNMENT_TYPE_SCHOOL_BOARD,
      "Mayor" =>                LEVEL_OF_GOVERNMENT_TYPE_MAYOR,
      "City Council" =>         LEVEL_OF_GOVERNMENT_TYPE_CITY_COUNCIL,
      "County Commissioner" =>  LEVEL_OF_GOVERNMENT_TYPE_COUNTY_COMMISSIONER,
      "County Prosecutor" =>    LEVEL_OF_GOVERNMENT_TYPE_COUNTY_PROSECUTOR,
      "Sheriff" =>              LEVEL_OF_GOVERNMENT_TYPE_SHERIFF,
      "State Representative" => LEVEL_OF_GOVERNMENT_TYPE_STATE_REPRESENTATIVE,
      "State Senator" =>        LEVEL_OF_GOVERNMENT_TYPE_STATE_SENATOR,
      "State Auditor" =>        LEVEL_OF_GOVERNMENT_TYPE_STATE_AUDITOR,
      "Secretary of State" =>   LEVEL_OF_GOVERNMENT_TYPE_SECRETARY_OF_STATE,
      "Governor" =>             LEVEL_OF_GOVERNMENT_TYPE_GOVERNOR,
      "US. Congressperson" =>   LEVEL_OF_GOVERNMENT_TYPE_CONGRESSPERSON,
      "US. Senator" =>          LEVEL_OF_GOVERNMENT_TYPE_SENATOR
  }

  def candidates_announced?
    candidates_announcement_date &&
       candidates_announcement_date < Time.now
  end

  def type_and_locale
    "#{locale} #{LEVEL_OF_GOVERNMENT_TYPES.invert[level_of_government]}"
  end

  def complete_name
    if election.external?
      type_and_locale
    else
      name
    end
  end
end