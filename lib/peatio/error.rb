class Peatio::Error < ::StandardError
  @@default_code = 2000
  @@default_status = 400

  attr :code, :text

  def initialize(opts = {})
    @code = opts[:code] || @@default_code
    @text = opts[:text] || ""

    @status = opts[:status] || @@default_status
    @message = {error: {code: @code, message: @text}}

    if @text != ""
      super("#{@code}: #{text}")
    else
      super("#{@code}")
    end
  end

  def inspect
    message = @text
    message += " (#{@reason})" unless @reason.nil?

    %[#<#{self.class.name}: #{message}>]
  end
end
