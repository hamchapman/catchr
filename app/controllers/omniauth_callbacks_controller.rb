class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def all
    auth = request.env['omniauth.auth']
    if current_user
      account_id = session[:account_id].nil? ? nil : session[:account_id]
      session.delete(:account_id)
      user = User.omniauth_update_or_create_service(auth, current_user, account_id)
      if user.persisted?
        provider_cookie = (auth.provider + '_oauth_popup').to_sym
        if cookies[provider_cookie]
          cookies[provider_cookie] = nil
          session[(auth.provider + '_omniauth_success').to_sym] = true
          return render 'auth_popup_closer', layout: false
        else
          flash[:notice] = 'Account authorized'
        end
      else
        flash[:error] = 'An error occurred'
      end
      redirect_to '/connections'
    else
      user = User.omniauth_login_or_signup(auth)
      if user.persisted?
        sign_in user
        redirect_to '/connections'
      else
        session['devise.user_attributes'] = user.attributes
        session['omniauth.auth'] = { uid: auth.uid, nickname: auth.info.nickname, token: auth.credentials.token, secret: auth.credentials.secret, provider: auth.provider }
        redirect_to new_user_registration_url
      end
    end
  end

  def failure
    flash[:error] = 'Account authorization failed'
    redirect_to '/connections'
  end

  alias_method :clef, :all
  alias_method :evernote, :all
  alias_method :facebook, :all
  alias_method :fitbit, :all
  alias_method :github, :all
  alias_method :instagram, :all
  alias_method :instapaper, :all
  alias_method :lastfm, :all
  alias_method :moves, :all
  alias_method :pocket, :all
  alias_method :rdio, :all
  alias_method :runkeeper, :all
  alias_method :twitter, :all
  alias_method :wunderlist, :all
end
