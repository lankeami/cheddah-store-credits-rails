class StoreCredit < ActiveRecord::Base
  belongs_to :shop
  belongs_to :campaign, optional: true
  belongs_to :shopify_customer, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expiry_hours, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }

  # Validate uniqueness: one completed credit per customer per campaign
  validate :unique_completed_credit_per_campaign

  before_validation :calculate_expires_at, on: :create

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :expired, -> { where('expires_at < ?', Time.current) }

  def mark_as_processing!
    update!(status: 'processing', processed_at: Time.current)
  end

  def mark_as_completed!(credit_id, shopify_customer = nil)
    attrs = {
      status: 'completed',
      shopify_credit_id: credit_id,
      processed_at: Time.current,
      error_message: nil
    }

    # Set shopify_customer relationship if provided
    attrs[:shopify_customer] = shopify_customer if shopify_customer

    update!(attrs)
  end

  def mark_as_failed!(error, shopify_customer = nil)
    attrs = {
      status: 'failed',
      processed_at: Time.current,
      error_message: error
    }

    # Set shopify_customer relationship if provided
    attrs[:shopify_customer] = shopify_customer if shopify_customer

    update!(attrs)
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  # Generate Shopify admin customer URL
  def shopify_customer_url
    return shopify_customer.shopify_customer_url if shopify_customer
    nil
  end

  def process_now!
    return if expired?

    mark_as_processing!

    service = ShopifyStoreCreditService.new(shop)
    result = service.create_store_credit(
      email: email,
      amount: amount,
      expires_at: expires_at,
      note: "Store credit - expires #{expires_at.strftime('%Y-%m-%d')}"
    )

    if result[:success]
      mark_as_completed!(result[:credit_id], result[:customer_id])
    else
      mark_as_failed!(result[:error], result[:customer_id])
    end

    result
  rescue => e
    mark_as_failed!(e.message)
    { success: false, error: e.message }
  end

  private

  def calculate_expires_at
    self.expires_at = Time.current + expiry_hours.hours if expiry_hours.present?
  end

  def unique_completed_credit_per_campaign
    # Only validate when setting status to completed
    return unless status == 'completed'

    # Check if there's already a completed credit for this email and campaign
    # Exclude the current record if it's being updated
    existing = shop.store_credits
                   .where(email: email, campaign_id: campaign_id, status: 'completed')
                   .where.not(id: id)
                   .exists?

    if existing
      if campaign
        errors.add(:base, "This customer has already received store credit from the '#{campaign.name}' campaign")
      else
        errors.add(:base, "This customer has already received store credit")
      end
    end
  end
end
