class Campaign < ActiveRecord::Base
  belongs_to :shop
  has_many :store_credits, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :shop_id }
  validates :shop_id, presence: true

  # Statistics methods
  def total_credits_count
    store_credits.count
  end

  def total_amount
    store_credits.sum(:amount)
  end

  def pending_count
    store_credits.pending.count
  end

  def completed_count
    store_credits.completed.count
  end

  def failed_count
    store_credits.failed.count
  end

  def stats
    {
      total_credits: total_credits_count,
      total_amount: total_amount,
      pending: pending_count,
      completed: completed_count,
      failed: failed_count
    }
  end
end
