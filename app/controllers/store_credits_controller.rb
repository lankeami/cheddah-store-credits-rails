class StoreCreditsController < ApplicationController
  require 'csv'

  def index
    @shop = current_shop
    @store_credits = current_shop.store_credits.order(updated_at: :desc).page(params[:page]).per(20)
    @campaigns = current_shop.campaigns.order(created_at: :desc)
    @stats = {
      total: current_shop.store_credits.count,
      pending: current_shop.store_credits.pending.count,
      completed: current_shop.store_credits.completed.count,
      failed: current_shop.store_credits.failed.count
    }
  end

  def new
  end

  def upload
    unless params[:csv_file].present?
      redirect_to store_credits_path(shopify_params), alert: 'Please select a CSV file to upload.'
      return
    end

    csv_file = params[:csv_file]

    unless csv_file.content_type == 'text/csv' || csv_file.original_filename.end_with?('.csv')
      redirect_to store_credits_path(shopify_params), alert: 'Please upload a valid CSV file.'
      return
    end

    # Get campaign if specified
    campaign = nil
    if params[:campaign_id].present? && params[:campaign_id] != ""
      campaign = current_shop.campaigns.find_by(id: params[:campaign_id])
    end

    begin
      results = process_csv(csv_file, campaign)

      if results[:errors].any?
        flash[:alert] = "Uploaded with errors. #{results[:success_count]} records added, #{results[:errors].count} failed."
        flash[:errors] = results[:errors]
      else
        message = "Successfully uploaded #{results[:success_count]} store credits"
        message += " to campaign '#{campaign.name}'" if campaign
        flash[:notice] = message + ". Processing will begin shortly."

        # Enqueue job to process the credits in Shopify
        ProcessStoreCreditsJob.perform_later(shop_domain: current_shop.shopify_domain)
      end
    rescue CSV::MalformedCSVError => e
      flash[:alert] = "Invalid CSV format: #{e.message}"
    rescue => e
      flash[:alert] = "Error processing CSV: #{e.message}"
      Rails.logger.error("CSV Upload Error: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    redirect_to store_credits_path(shopify_params)
  end

  private

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: current_shopify_domain)
  end

  def shopify_params
    {
      shop: params[:shop],
      host: params[:host],
      embedded: params[:embedded],
      id_token: params[:id_token]
    }.compact
  end

  def process_csv(file, campaign = nil)
    success_count = 0
    errors = []
    line_number = 1

    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      line_number += 1

      begin
        # Validate required columns
        unless row[:email] && row[:amount] && row[:expiry_hours]
          errors << "Line #{line_number}: Missing required fields (email, amount, expiry_hours)"
          next
        end

        email = row[:email].to_s.strip

        # Check for existing completed credit for this email and campaign
        existing_completed = current_shop.store_credits
                                        .where(email: email, campaign_id: campaign&.id, status: 'completed')
                                        .exists?

        # Create store credit
        store_credit = current_shop.store_credits.create!(
          email: email,
          amount: row[:amount].to_f,
          expiry_hours: row[:expiry_hours].to_i,
          campaign: campaign
        )

        # If duplicate, mark as failed immediately
        if existing_completed
          error_msg = if campaign
            "Customer has already received store credit from the '#{campaign.name}' campaign"
          else
            "Customer has already received store credit"
          end
          store_credit.update!(
            status: 'failed',
            error_message: error_msg,
            processed_at: Time.current
          )
          errors << "Line #{line_number}: #{error_msg}"
        else
          success_count += 1
        end
      rescue ActiveRecord::RecordInvalid => e
        errors << "Line #{line_number}: #{e.message}"
      rescue => e
        errors << "Line #{line_number}: #{e.message}"
      end
    end

    { success_count: success_count, errors: errors }
  end
end
