class CampaignsController < ApplicationController
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]

  def index
    @campaigns = current_shop.campaigns.order(created_at: :desc)
  end

  def show
    @stats = @campaign.stats
    @credits = @campaign.store_credits.order(created_at: :desc).limit(100)
  end

  def new
    @campaign = current_shop.campaigns.build
  end

  def create
    @campaign = current_shop.campaigns.build(campaign_params)

    if @campaign.save
      redirect_to campaigns_path, notice: "Campaign '#{@campaign.name}' created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @campaign.update(campaign_params)
      redirect_to campaign_path(@campaign), notice: "Campaign updated successfully."
    else
      render :edit
    end
  end

  def destroy
    name = @campaign.name
    @campaign.destroy
    redirect_to campaigns_path, notice: "Campaign '#{name}' deleted successfully."
  end

  private

  def current_shop
    @current_shop ||= Shop.find_by(shopify_domain: current_shopify_domain)
  end

  def set_campaign
    @campaign = current_shop.campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:name, :description)
  end
end
