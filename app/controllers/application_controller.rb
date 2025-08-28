class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  def switch_language
    locale = params[:locale].to_s.strip
    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
    end
    redirect_back(fallback_location: root_path)
  end

  private

  def set_locale
    I18n.locale = session[:locale]&.to_sym || I18n.default_locale
  end
end
