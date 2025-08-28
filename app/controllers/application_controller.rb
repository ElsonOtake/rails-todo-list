class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_locale

  def set_locale
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      redirect_to request.referer || root_path
    else
      redirect_to root_path
    end
  end

  private

  def configure_locale
    # Check for session locale, then browser preference, then default
    if session[:locale].present? && I18n.available_locales.include?(session[:locale].to_sym)
      I18n.locale = session[:locale]
    else
      I18n.locale = extract_locale_from_accept_language_header || I18n.default_locale
    end
  end

  def extract_locale_from_accept_language_header
    request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first&.to_sym if request.env["HTTP_ACCEPT_LANGUAGE"]
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
