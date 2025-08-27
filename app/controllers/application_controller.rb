class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  def switch_language
    session[:locale] = params[:locale] if I18n.available_locales.include?(params[:locale]&.to_sym)
    redirect_back_or_to(root_path)
  end

  private

  def set_locale
    I18n.locale = session[:locale] || I18n.default_locale
  end
end
