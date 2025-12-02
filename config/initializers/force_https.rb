# Force Rails to recognize requests as HTTPS for proper URL generation
class ForceHttpsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    env['HTTPS'] = 'on'
    env['rack.url_scheme'] = 'https'
    env['HTTP_X_FORWARDED_PROTO'] = 'https'
    @app.call(env)
  end
end

Rails.application.config.middleware.insert_before 0, ForceHttpsMiddleware
