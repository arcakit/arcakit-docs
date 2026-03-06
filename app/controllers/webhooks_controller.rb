class WebhooksController < ApplicationController
  skip_forgery_protection

  def github
    return head :forbidden unless valid_signature?

    Rails.cache.clear
    head :ok
  end

  private

  def valid_signature?
    secret = ENV["GITHUB_WEBHOOK_SECRET"]
    return true if secret.blank?

    expected = "sha256=" + OpenSSL::HMAC.hexdigest("sha256", secret, request.raw_post)
    ActiveSupport::SecurityUtils.secure_compare(expected, request.headers["X-Hub-Signature-256"].to_s)
  end
end
