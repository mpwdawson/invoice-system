require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 1400, 900 ],
    js_errors: true,
    process_timeout: 15,
    timeout: 10
  )
end

Capybara.default_max_wait_time = 5
