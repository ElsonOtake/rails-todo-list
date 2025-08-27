class LanguagesController < ApplicationController
  def change
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      I18n.locale = params[:locale]
    end
    
    redirect_back(fallback_location: root_path)
  end
end