class Coach < ActiveRecord::Base
  belongs_to :train

  EXCLUDED_ATTR = %w(id type train_id created_at updated_at counting_number).freeze
  SUBCLASS_LIST = %w(CompartmentCoach EconomyCoach SleepingCoach SuburbanCoach).freeze

  validates :type, presence: true, inclusion: { in: SUBCLASS_LIST,
                                                message: "%{value} is not a valid coach type" }
  validates :train_id, presence: { message: "must be chosen" }
  validates :counting_number, presence: true, numericality: true,
                              uniqueness: { scope: :train_id,
                                            message: "should be unique per train" }

  scope :compartment_coaches, -> { where(type: 'CompartmentCoach') }
  scope :economy_coaches, -> { where(type: 'EconomyCoach') }
  scope :sleeping_coaches, -> { where(type: 'SleepingCoach') }
  scope :suburban_coaches, -> { where(type: 'SuburbanCoach') }

  before_validation :set_counting_number

  def set_counting_number
    unless Coach.where("train_id = ? AND id = ?", train, self).exists?
      @maximum = Coach.where(train_id: train).maximum("counting_number")
      self.counting_number = (@maximum.present? ? @maximum : 0) + 1
    end
  end

  def self.types
    SUBCLASS_LIST
  end

  def seats_list
    attributes.delete_if { |k, _v| EXCLUDED_ATTR.include?(k) }
  end

  def allowed_list
    seats_list
  end
end

class SuburbanCoach < Coach
  SEATS = %w(simple_seats).freeze
  SEATS.each { |seat| validates seat, presence: true, numericality: { only_integer: true } }
  validates :top_seats, :bottom_seats, :side_top_seats, :side_bottom_seats, absence: true

  def allowed_list
    Hash[SEATS.collect { |item| [item, ""] }]
  end
end

class EconomyCoach < Coach
  SEATS = %w(top_seats bottom_seats side_top_seats side_bottom_seats).freeze
  SEATS.each { |seat| validates seat, presence: true, numericality: { only_integer: true } }
  validates :simple_seats, absence: true

  def allowed_list
    Hash[SEATS.collect { |item| [item, ""] }]
  end
end

class CompartmentCoach < Coach
  SEATS = %w(top_seats bottom_seats).freeze
  SEATS.each { |seat| validates seat, presence: true, numericality: { only_integer: true } }
  validates :simple_seats, :side_top_seats, :side_bottom_seats, absence: true

  def allowed_list
    Hash[SEATS.collect { |item| [item, ""] }]
  end
end

class SleepingCoach < Coach
  SEATS = %w(bottom_seats).freeze
  SEATS.each { |seat| validates seat, presence: true, numericality: { only_integer: true } }
  validates :top_seats, :simple_seats, :side_top_seats, :side_bottom_seats, absence: true

  def allowed_list
    Hash[SEATS.collect { |item| [item, ""] }]
  end
end
