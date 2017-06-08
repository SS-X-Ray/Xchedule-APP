require 'pony'

# Send an email for account registration request verification
class EmailRegistrationVerification
  def initialize(config)
    @config = config
    Pony.options = {
      from: "noreply@#{config.SENDGRID_DOMAIN}",
      via: :smtp,
      via_options: {
        address: 'smtp.sendgrid.net',
        port: '587',
        domain: @config.SENDGRID_DOMAIN,
        user_name: @config.SENDGRID_USERNAME,
        password: @config.SENDGRID_PASSWORD,
        authentication: :plain,
        enable_starttls_auto: true
      }
    }
  end

  def call(username:, email:)
    registration = { username: username, email: email }
    token_encrypted = SecureMessage.encrypt(registration)

    Pony.mail(to: registration[:email],
              subject: 'Your Xchedule Account is Almost Ready',
              html_body: registration_email(token_encrypted))
  end

  private

  def registration_email(token)
    verification_url = "#{@config.APP_URL}/account/register/#{token}/verify"

    <<~END_EMAIL
      <H1>Xchedule Registration Received<H1>
      <p>Please <a href=\"#{verification_url}\">click here</a> to validate your
      email. You will be asked to set a password to activate your account.</p>
    END_EMAIL
  end
end
