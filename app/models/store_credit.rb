class StoreCredit < ActiveRecord::Base
  belongs_to :shop
  belongs_to :campaign, optional: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :expiry_hours, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :status, presence: true, inclusion: { in: %w[pending processing completed failed] }

  before_validation :calculate_expires_at, on: :create

  scope :pending, -> { where(status: 'pending') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :expired, -> { where('expires_at < ?', Time.current) }

  def mark_as_processing!
    update!(status: 'processing', processed_at: Time.current)
  end

  def mark_as_completed!(credit_id, customer_id = nil)
    update!(
      status: 'completed',
      shopify_credit_id: credit_id,
      shopify_customer_id: customer_id,
      processed_at: Time.current,
      error_message: nil
    )
  end

  def mark_as_failed!(error, customer_id = nil)
    update!(
      status: 'failed',
      shopify_customer_id: customer_id,
      processed_at: Time.current,
      error_message: error
    )
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  # Generate Shopify admin customer URL
  def shopify_customer_url
    return nil unless shopify_customer_id && shop
    "https://#{shop.shopify_domain}/admin/customers/#{shopify_customer_id}"
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
end
