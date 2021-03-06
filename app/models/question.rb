class Question < ApplicationRecord
  belongs_to :questionnaire_section
  has_many   :choices, dependent: :destroy
  has_many   :answers, dependent: :destroy

  accepts_nested_attributes_for :choices

  validates :text, presence: true

  QUESTION_TYPE_SHORT_TEXT =      'short_text'
  QUESTION_TYPE_LONG_TEXT =       'long_text'
  QUESTION_TYPE_MULTIPLE_CHOICE = 'multiple_choice'
  QUESTION_TYPE_CHECKBOXES =      'checkboxes'

  QUESTION_TYPES = {
    "Short text" => QUESTION_TYPE_SHORT_TEXT,
    "Long text" => QUESTION_TYPE_LONG_TEXT,
    "Single choice" => QUESTION_TYPE_MULTIPLE_CHOICE,
    "Multiple choices" => QUESTION_TYPE_CHECKBOXES
  }

  default_scope ->{ order('order_index asc') }

  def new_answer(candidacy: nil, index: nil)
    Answer.new(candidacy: candidacy, question: self, order_index: index)
  end

  def has_choices?
    question_type == QUESTION_TYPE_CHECKBOXES || question_type == QUESTION_TYPE_MULTIPLE_CHOICE
  end
end