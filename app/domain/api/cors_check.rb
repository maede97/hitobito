#  Copyright (c) 2018, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Api::CorsCheck
  attr_reader :request

  def initialize(request)
    @request = request
  end

  def allowed?(origin)
    return false if oauth_token.present? && !oauth_token_allows_origin?(origin)

    return false if service_token.present? && !service_token_allows_origin?(origin)

    # In CORS preflight OPTIONS requests, the token headers are not sent along.
    # So this check is as specific as it can be for these cases.
    return false if no_token_present? && !cors_origin_allowed?(origin)

    true
  end

  private

  def cors_origin_allowed?(origin)
    CorsOrigin::where(origin: origin).exists?
  end

  def service_token_allows_origin?(origin)
    allows_origin?(service_token, origin)
  end

  def oauth_token_allows_origin?(origin)
    oauth_token_has_api_access? && allows_origin?(oauth_token.application, origin)
  end

  def oauth_token_has_api_access?
    oauth_token.application.includes_scope?(:api)
  end

  def allows_origin?(auth_method, origin)
    auth_method.cors_origins.where(origin: origin).exists?
  end

  def oauth_token
    token_authentication.oauth_token
  end

  def service_token
    token_authentication.service_token
  end

  def no_token_present?
    [:service_token, :oauth_token].none? { |token| send(token).present? }
  end

  def token_authentication
    @token_authentication ||= Authenticatable::Tokens.new(request, request.params)
  end
end